from django.apps import AppConfig
from django.conf import settings
from django.utils.translation import ugettext_lazy as _

from django_mysql.checks import register_checks
from django_mysql.rewrite_query import REWRITE_MARKER, rewrite_query
from django_mysql.utils import mysql_connections


class MySQLConfig(AppConfig):
    name = "django_mysql"
    verbose_name = _("MySQL extensions")

    def ready(self):
        self.add_database_instrumentation()
        self.add_lookups()
        register_checks()

    def add_database_instrumentation(self):
        if not getattr(settings, "DJANGO_MYSQL_REWRITE_QUERIES", False):
            return
        for alias, connection in mysql_connections():
            # Rather than use the documented API of the `execute_wrapper()`
            # context manager, directly insert the hook. This is done because:
            # 1. Deleting the context manager closes it, so it's not possible
            # to enter it here and not exit it, unless we store it forever in
            # some variable.
            # 2. We want to be idempotent and only install the hook once.
            if rewrite_hook not in connection.execute_wrappers:
                connection.execute_wrappers.append(rewrite_hook)

    def add_lookups(self):
        from django.db.models import CharField, TextField
        from django_mysql.models.lookups import CaseSensitiveExact, Soundex, SoundsLike

        CharField.register_lookup(CaseSensitiveExact)
        CharField.register_lookup(SoundsLike)
        CharField.register_lookup(Soundex)
        TextField.register_lookup(CaseSensitiveExact)
        TextField.register_lookup(SoundsLike)
        TextField.register_lookup(Soundex)


def rewrite_hook(execute, sql, params, many, context):
    if (
        getattr(settings, "DJANGO_MYSQL_REWRITE_QUERIES", False)
        and REWRITE_MARKER in sql
    ):
        sql = rewrite_query(sql)
    return execute(sql, params, many, context)
