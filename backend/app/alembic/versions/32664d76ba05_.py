"""empty message

Revision ID: 32664d76ba05
Revises: 2d3c524627e2
Create Date: 2022-12-01 11:12:42.272773

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '32664d76ba05'
down_revision = '2d3c524627e2'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('cost_types',
    sa.Column('id', sa.Integer(), autoincrement=False, nullable=False),
    sa.Column('name', sa.String(), nullable=True),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('name')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('cost_types')
    # ### end Alembic commands ###
