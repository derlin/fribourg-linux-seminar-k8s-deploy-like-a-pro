# Helmfile for deploying rickroller

Learn more about helmfile at helmfile.readthedocs.io/.

To deploy rickroller, install helmfile and use:
```bash
helmfile apply
```

Uninstall with `helmfile destroy`.

The `helmfile-env.yaml` shows a more complex example of helmfile that uses Go templates and environments.
You can use it by passing the `-f helmfile-env.yaml` option to helmfile.