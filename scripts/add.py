"""
Add entries for books, presentations, posts or themes to the website.

Writes the given entry to `nix/data/`, fills in metadata that can be inferred,
and evaluates the flake. If the operation fails, changes are reverted
"""

from __future__ import annotations

import argparse
import contextlib
import datetime
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Generator
from pathlib import Path
from typing import Any

ROOT = Path(
    subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
)
DATA = ROOT / "nix/data"
PINS = ROOT / "npins/sources.json"

SLUG_RE = re.compile(r"[^a-z09]+")
ATTR_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_'-]*")
THEME_PIN_RE = re.compile(r"^(?:neovim|nvim|vim)-|[.-](?:neovim|nvim|vim)$")
BRANCH_RE = re.compile(r"ref: refs/heads/(\S+)")


def run(
    *command: str | Path, **options: Any
) -> subprocess.CompletedProcess[str]:
    """Run a command from the repository root"""
    return subprocess.run(
        [str(word) for word in command],
        cwd=ROOT,
        check=True,
        text=True,
        **options,
    )


def nixify(value: str | int) -> str:
    """Format a string or number as a Nix value."""
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False).replace("${", "\\${")
    return str(value)


def attrs(fields: dict[str, str | str | int | None]) -> str:
    """Format fields and values as a Nix attribute set."""
    return (
        "{"
        + "".join(
            f"{key} = {nixify(value)}; "
            for key, value in fields.items()
            if value is not None
        )
        + "}"
    )


def append(file: Path, text: str) -> None:
    """Append an entry to a Nix list or attribute set."""
    lines = file.read_text(encoding="utf-8").rstrip("\n").split("\n")

    # An empty one, as nixfmt writes it.
    if lines[-1] in ("[ ]", "{ }"):
        lines[-1:] = list(lines[-1][::2])

    if lines[-1] not in ("]", "}"):
        raise RuntimeError(f"{file} doesn't end in ] or }}")

    file.write_text(
        "\n".join([*lines[:-1], text, lines[-1]]) + "\n", encoding="utf-8"
    )
    run("nixfmt", file)


@contextlib.contextmanager
def undoing(*files: Path) -> Generator[None]:
    """Restore files if the operation inside the context fails."""
    before = {
        file: file.read_bytes() if file.exists else None for file in files
    }

    try:
        yield
    except BaseException:
        for file, content in before.items():
            if content is None:
                _ = run(
                    "git", "rm", "--quiet", "--cached", "--ignore-unmatch", file
                )
                file.unlink(missing_ok=True)
            else:
                file.write_bytes(content)
        raise


def track(file: Path) -> None:
    """Make the file visible to the flake."""
    _ = run("git", "add", "--intend-to-add", file)


def listed(name: str, fields: dict[str, str | int | None]) -> None:
    """Add an entry to a list if the flake still evaluates with it."""
    file = DATA / f"{name}.nix"

    with undoing(file):
        append(file, attrs(fields))
        _ = run(
            "nix",
            "eval",
            "--raw",
            ".#default.drvPath",
            stdout=subprocess.DEVNULL,
        )

    print(f"added to {file.relative_to(ROOT)}")


def book(args: argparse.Namespace) -> None:
    listed(
        "books",
        {"title": args.title, "date": args.date, "symlink": args.url},
    )


def external_post(args: argparse.Namespace) -> None:
    listed(
        "external-posts",
        {"title": args.title, "date": args.date, "href": args.url},
    )


def slide(args: argparse.Namespace) -> None:
    if not args.recording and not args.pdf:
        raise ValueError("a slide is a --recording, a --pdf or both")

    fields = {
        "title": args.title,
        "data": args.date,
        "symlink": args.recording,
        "extension": args.extension,
    }

    if not args.pdf:
        listed("slides", fields)
        return

    pdf = ROOT / "slides" / args.pdf.name

    with undoing(pdf):
        if not pdf.exists():
            shutil.copy2(args.pdf, pdf)
            track(pdf)

        listed("slides", fields | {"pdf": pdf.name, "size": pdf.stat().st_size})


def post(args: argparse.Namespace) -> None:
    slug = SLUG_RE.sub("-", args.title.lower()).strip("-")
    file = ROOT / "notes/_posts" / f"{args.date}-{slug}.md"

    if file.exists():
        raise FileExistsError(f"{file.relative_to(ROOT)} is there already")

    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(
        f"---\ntitle: {json.dumps(args.title, ensure_ascii=False)}\n---\n\n",
        encoding="utf-8",
    )
    track(file)
    print(file.relative_to(ROOT))


def theme(args: argparse.Namespace) -> None:
    pins = json.loads(PINS.read_text(encoding="utf-8"))["pins"]

    owner, _, repository = args.plugin.partition("/")

    if repository:
        pin = args.pin or THEME_PIN_RE.sub("", repository.lower())
    elif args.plugin in pins:
        pin = args.plugin
    else:
        available = ", ".join(pins)
        raise ValueError(
            f"{args.plugin} is neither <owner>/<repository> "
            f"nor one of the pins: {available}"
        )

    name = args.name or args.colorname or pin

    fields = {
        "plugin": pin if pin != name else None,
        "colorscheme": (args.colorscheme if args.colorscheme != name else None),
        "background": "light" if args.light else None,
        "lualine": args.lualine,
        "setup": args.setup,
    }

    attr = name if ATTR_RE.fullmatch(name) else nixify(name)

    themes = DATA / "themes.nix"

    with undoing(themes, PINS):
        if pin not in pins:
            url = f"https://github.com/{owner}/{repository}"
            head = run(
                "git", "ls-remote", "--symref", url, "HEAD", capture_output=True
            ).stdout

            branch_match = BRANCH_RE.search(head)
            if branch_match is None:
                raise RuntimeError(
                    f"couldn't determine default branch for {url}"
                )

            branch = args.branch or branch_match.group(1)

            _ = run(
                "npins",
                "add",
                "--name",
                pin,
                "github",
                owner,
                repository,
                "--branch",
                branch,
            )

        append(themes, f"{attr} = {attrs(fields)};")

        # Its names are checked against the plugin, and Neovim loads it.
        _ = run("nix", "build", "--no-link", ".#colorschemes")

    print(
        f"added to {themes.relative_to(ROOT)}: "
        f"`nix run`, then :colorscheme {name}"
    )


def main() -> None:
    today = datetime.date.today().isoformat()

    parser = argparse.ArgumentParser(
        prog="add", description="Adds something to the site."
    )

    commands = parser.add_subparsers(metavar="<what>", required=True)

    def command(
        name: str, function: Any, summary: str
    ) -> argparse.ArgumentParser:
        subparser = commands.add_parser(
            name,
            help=summary,
            description=summary,
        )
        subparser.set_defaults(run=function)

        if function is not theme:
            _ = subparser.add_argument("title")
            _ = subparser.add_argument(
                "--date", default=today, help="instead of today, as YYYY-MM-DD"
            )

        return subparser

    _ = command("book", book, "a book in books/").add_argument(
        "url", help="source URL"
    )
    _ = command(
        "external-post", external_post, "a post published elsewhere"
    ).add_argument("url", help="source URL")
    _ = command("post", post, "an empty post draft in notes/")

    slides = command(
        "slide",
        slide,
        "a presentation in slides/",
    )
    slides.add_argument("--recording", metavar="URL")
    slides.add_argument(
        "--extension",
    )
    slides.add_argument(
        "--pdf",
        type=Path,
        metavar="FILE",
        help="copied to slides/",
    )

    themes = command(
        "theme",
        theme,
        "a Neovim colorscheme",
    )
    themes.add_argument(
        "plugin",
        help="<owner>/<repository> on GitHub, or a plugin already pinned",
    )
    themes.add_argument(
        "name",
        nargs="?",
        help="the theme's name",
    )
    themes.add_argument(
        "--colorscheme",
        help="what :colorscheme loads",
    )
    themes.add_argument(
        "--light",
        action="store_true",
        help="load it with a light background",
    )
    themes.add_argument(
        "--lualine",
        metavar="THEME",
        help="lualine's theme",
    )
    themes.add_argument(
        "--setup",
        metavar="COMMANDS",
        help="vim commands to run before loading it",
    )
    themes.add_argument(
        "--pin",
        help="the pin's name",
    )
    themes.add_argument(
        "--branch",
        help="the branch to pin",
    )

    args = parser.parse_args()

    try:
        args.run(args)
    except subprocess.CalledProcessError as error:
        sys.exit(f"{error.cmd[0]} failed: nothing was added")
    except (FileExistsError, ValueError, RuntimeError) as error:
        sys.exit(str(error))


if __name__ == "__main__":
    main()
