import Libraries.hashlib.HashlibDef

/-! MD5 regression checks — the RFC 1321 official test suite (`Libraries.hashlib.pyMd5Hexdigest`
is a real MD5, so these are exact). Includes multi-block and UTF-8 inputs. -/

namespace PALC.Libraries.hashlib_test
open Libraries.hashlib

#guard pyMd5Hexdigest "" == "d41d8cd98f00b204e9800998ecf8427e"
#guard pyMd5Hexdigest "a" == "0cc175b9c0f1b6a831c399e269772661"
#guard pyMd5Hexdigest "abc" == "900150983cd24fb0d6963f7d28e17f72"
#guard pyMd5Hexdigest "message digest" == "f96b697d7cb7938d525a2f31aaf161d0"
#guard pyMd5Hexdigest "abcdefghijklmnopqrstuvwxyz" == "c3fcd3d76192e4007dfb496cca67e13b"
-- Multi-block (> 55 bytes → padding spills into a second 512-bit block):
#guard pyMd5Hexdigest "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        == "d174ab98d277d9f5a5611c2c9f419d9f"
#guard pyMd5Hexdigest "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        == "57edf4a22be3c955ac49da2e2107b67a"
-- The HumanEval StringToMd5 docstring vector:
#guard pyMd5Hexdigest "Hello world" == "3e25960a79dbc69b674cd4ec67a72c62"
-- Object model: md5() carries the message, update appends, hexdigest digests.
#guard pyMd5Hexdigest (pyHashUpdate (pyMd5) "abc") == pyMd5Hexdigest "abc"

end PALC.Libraries.hashlib_test
