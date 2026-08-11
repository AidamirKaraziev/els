import logging

from src.core.db.init_db import create_initial_data

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main() -> None:
    logger.info("Creating initial data")
    create_initial_data()

    logger.info("Initial data created")


if __name__ == "__main__":
    main()
