"""empty message

Revision ID: 31d40c11e77e
Revises: d4caa590f9ed
Create Date: 2022-09-29 11:17:05.762176

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '31d40c11e77e'
down_revision = 'd4caa590f9ed'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('universal_users',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(), nullable=True),
    sa.Column('email', sa.String(), nullable=True),
    sa.Column('password', sa.String(), nullable=True),
    sa.Column('contact_phone', sa.String(), nullable=True),
    sa.Column('birthday', sa.Date(), nullable=True),
    sa.Column('photo', sa.String(), nullable=True),
    sa.Column('location_id', sa.Integer(), nullable=True),
    sa.Column('role_id', sa.Integer(), nullable=True),
    sa.Column('working_specialty_id', sa.Integer(), nullable=True),
    sa.Column('identity_card', sa.String(), nullable=True),
    sa.Column('is_actual', sa.Boolean(), nullable=True),
    sa.Column('company_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['company_id'], ['company.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['location_id'], ['locations.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['working_specialty_id'], ['working_specialty.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('email')
    )
    op.drop_table('universaluser')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('universaluser',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('email', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('password', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('contact_phone', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('birthday', sa.DATE(), autoincrement=False, nullable=True),
    sa.Column('photo', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('location_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('role_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('is_actual', sa.BOOLEAN(), autoincrement=False, nullable=True),
    sa.Column('working_specialty_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('identity_card', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('company_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['company_id'], ['company.id'], name='universaluser_company_id_fkey', ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['location_id'], ['locations.id'], name='universaluser_location_id_fkey', ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['role_id'], ['roles.id'], name='universaluser_role_id_fkey', ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['working_specialty_id'], ['working_specialty.id'], name='universaluser_working_specialty_id_fkey', ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id', name='universaluser_pkey'),
    sa.UniqueConstraint('email', name='universaluser_email_key')
    )
    op.drop_table('universal_users')
    # ### end Alembic commands ###
