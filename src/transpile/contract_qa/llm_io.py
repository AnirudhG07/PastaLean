"""The only two places an LLM is allowed near this pipeline.

`generator`  — writes/rewrites the contracts. Never trusted; everything it emits goes back through
               the gates.
`critic`     — answers the one question no parser or test run can: does this specification capture
               what the function is FOR, or an incidental property that happens to hold? Advisory
               only. It can add a repair hint; it can never pass or fail a unit.

Both are pluggable. With no API key configured, `stub_generator` / `no_critic` keep the rest of the
pipeline fully operational — the deterministic gates are the ones that decide anything.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Callable, Protocol

from .unit import Unit

REPO_ROOT = Path(__file__).resolve().parents[3]
SYSTEM_PROMPT = REPO_ROOT / "docs" / "contract-prompt-system.md"


class Generator(Protocol):
    def __call__(self, unit: Unit, previous: str | None, feedback: list[str]) -> str: ...


class NoLLM(RuntimeError):
    """No API key / no provider configured."""


def have_key(provider: str) -> bool:
    """Is this provider usable? Lets a sweep degrade to verify-only instead of failing per unit."""
    try:
        return bool(_llm_module().env_api_key(provider))
    except Exception:  # noqa: BLE001
        return False


def _llm_module():
    try:
        from .. import llm  # noqa: PLC0415
    except ImportError:
        # Imported as a top-level `contract_qa` (repo checkout, `src/transpile` on the path), so
        # there is no parent package to reach `llm` through; fall back to the installed one.
        try:
            from pastalean.transpile import llm  # noqa: PLC0415
        except ImportError as exc:
            raise NoLLM("LLM calls need the installed `pastalean` package "
                        "(uv pip install -e .); the deterministic gates do not") from exc
    return llm


def _extract_python(text: str) -> str:
    if "```python" in text:
        text = text.split("```python", 1)[1]
    elif text.startswith("```"):
        text = text[3:]
    if "```" in text:
        text = text.split("```", 1)[0]
    return text.strip() + "\n"


REPAIR_PREAMBLE = """\
Your previous annotation of this program was REJECTED by an automated verifier. The verifier is
deterministic: it parses the file, runs it against the recorded test inputs, re-evaluates every
`Ensures` with `Result()` bound to the value actually returned, and mutation-tests the specification
against deliberately-broken variants of the implementation. Its findings are FACTS, not opinions.

Fix every finding below and output the corrected program. Do not weaken a contract to make a
finding go away unless the finding says the contract is FALSE — if the finding is that a wrong
implementation slips past your specification, the specification must get STRONGER.
"""


def llm_generator(provider: str = "gemini", model: str | None = None,
                  api_key: str | None = None) -> Generator:
    """The default generator: the checked-in contract system prompt, plus the verifier's findings
    on a repair turn (execution-guided repair, in the style of Reflexion / self-debugging)."""
    system = SYSTEM_PROMPT.read_text()

    def generate(unit: Unit, previous: str | None, feedback: list[str]) -> str:
        llm = _llm_module()
        chosen = model or llm.default_model_for(provider)
        parts = []
        if previous and feedback:
            parts.append(REPAIR_PREAMBLE)
            parts.append("## Verifier findings\n\n" + "\n".join(f"- {f}" for f in feedback))
            parts.append("## Your previous attempt\n\n```python\n" + previous + "\n```")
            parts.append("## The original, unannotated program\n\n```python\n"
                         + unit.reference + "\n```")
        else:
            parts.append("```python\n" + unit.reference + "\n```")
        if unit.statement.strip():
            parts.append("## What the function is for\n\n" + unit.statement.strip()[:2000])
        response = llm.model_response_gen("\n\n".join(parts), task=system, provider=provider,
                                          model=chosen, api_key=api_key)
        return _extract_python(response or "")

    return generate


def stub_generator(sources: dict[str, str] | None = None) -> Generator:
    """A generator with no network: returns a canned source per module, else echoes the previous
    attempt. Lets the whole repair loop be exercised (and unit-tested) with no API key."""
    table = sources or {}

    def generate(unit: Unit, previous: str | None, feedback: list[str]) -> str:
        if unit.module in table:
            return table[unit.module]
        if previous is not None:
            return previous
        raise NoLLM(f"stub generator has nothing for {unit.module}")

    return generate


CRITIC_SYSTEM = """\
You are reviewing a FORMAL SPECIFICATION, not code. You are given a Python function, its purpose,
and the contracts someone wrote for it. A separate deterministic verifier has ALREADY established
that the contracts are well-formed, do not change behaviour, and are true on every recorded input.
Do not re-check any of that.

Answer only the question a test run cannot: does the specification pin down what this function is
FOR, or does it merely state an incidental property that happens to hold?

Reply with a JSON object and nothing else:
{
  "captures_intent": true|false,
  "score": 0-5,                       // 5 = a wrong implementation could not possibly satisfy it
  "missing_property": "...",          // the single most important clause that is absent, or ""
  "reason": "..."                     // one or two sentences
}
"""

Critic = Callable[[Unit, str], dict]


def llm_critic(provider: str = "gemini", model: str | None = None,
               api_key: str | None = None) -> Critic:
    def critique(unit: Unit, source: str) -> dict:
        llm = _llm_module()
        chosen = model or llm.default_model_for(provider)
        prompt = (f"## Purpose\n\n{unit.statement.strip()[:2000]}\n\n"
                  f"## The contracted program\n\n```python\n{source}\n```")
        raw = llm.model_response_gen(prompt, task=CRITIC_SYSTEM, provider=provider, model=chosen,
                                     json_output=True, api_key=api_key)
        try:
            return json.loads(raw)
        except (TypeError, json.JSONDecodeError):
            return {"captures_intent": None, "score": None, "reason": (raw or "")[:200]}

    return critique


def no_critic(_unit: Unit, _source: str) -> dict:
    return {}
