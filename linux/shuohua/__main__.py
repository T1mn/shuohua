"""Entry point: python -m shuohua."""

from .app import App


def main() -> None:
    app = App()
    app.run()


if __name__ == "__main__":
    main()
