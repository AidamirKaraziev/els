"""empty message

Revision ID: 0b015ab6bc7d
Revises: 8a5d7dd168ea
Create Date: 2022-07-19 07:32:00.546409

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0b015ab6bc7d'
down_revision = '8a5d7dd168ea'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint('device_user_id_fkey', 'device', type_='foreignkey')
    op.create_foreign_key(None, 'device', 'users', ['user_id'], ['id'])
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint(None, 'device', type_='foreignkey')
    op.create_foreign_key('device_user_id_fkey', 'device', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    # ### end Alembic commands ###
