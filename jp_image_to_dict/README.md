# jp_image_to_dict

A new Flutter project.

## Deploying

Build targeting web with the following `--dart-define` arguments.

| Argument | Type | Default Value | Description |
-----------|------|---------------|-------------|
| IS_DEVELOPMENT | bool | true | Enables debug mode. Prevents the embedded page from navigating unless ALLOW_EMBED is true. |
| ALLOW_EMBED | bool | opposite of IS_DEVELOPMENT | If on, the embedded web page will navigate when text is captured. |
| USING_JISHO | String | `LORENZI` | Sets the site to embed for dictionary lookups.<br>**Allowed values**: `LORENZI` or `JISHO.ORG` |
| USING_API | String | `LOCAL` | Sets the base URL for the backend. Check ApiConstants class in lib/constants.dart for details and descriptions.<br>**Allowed values**: `LOCAL`, `MOBILE_TEST`, `RENDER`, `SELFHOSTED`. |