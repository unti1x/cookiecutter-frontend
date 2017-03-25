import os
import sys

def cleanup(folder, skip_ext):
    working = os.path.abspath(os.path.join(os.path.curdir))
    clean_dir = os.path.join(working, "src", folder)

    for f in os.listdir(clean_dir):
        if not f.endswith("." + skip_ext):
            os.unlink(os.path.join(clean_dir, f))

def clean_templates():
    cleanup("templates", "{{cookiecutter.template_engine}}")

def clean_styles():
    cleanup("styles", "{{cookiecutter.style_engine}}")

def main():
    clean_styles()
    clean_templates()

if __name__ == '__main__':
    main()
