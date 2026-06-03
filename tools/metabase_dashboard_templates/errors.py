"""Exceptions for the Metabase dashboard template tool."""


class TemplateError(Exception):
    """A dashboard export/apply operation failed in a way worth explaining to
    the user.  Carries a ready-to-display, actionable message."""


class DuplicateDashboardError(TemplateError):
    """A dashboard with the target name already exists in the target
    collection.  Raised by apply unless the caller passes force=True."""
