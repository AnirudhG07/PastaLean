# No __init__: class-level field defaults; C() builds an all-defaults instance.
# Exercises: struct fields with defaults, the no-__init__ `C.new := default` path in heap mode.
class Config:
    width = 80
    height = 24

    def area(self):
        return self.width * self.height
