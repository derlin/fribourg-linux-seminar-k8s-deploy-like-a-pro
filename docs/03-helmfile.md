Usually, an application is composed of many microservices, each of them packaged as a helm chart.
When you want to install or upgrade the application as a whole, how would you proceed?
Running 20+ `helm upgrade` doesn't seem like a very interesting job. Moreover, charts may:

* have dependencies on others,
* share some common configurations,
* require a different configuration depending on the environment (demo, prod, etc.),
* need to be installed in a specific order (a service may need a database to be running first to start properly).

Enter [helmfile](https://helmfile.readthedocs.io/)!

## What is Helmfile

!!! warning 

    Even though Helmfile is used in production environments [across multiple organizations](https://helmfile.readthedocs.io/en/latest/users/),
    it is still in its early stage of development, hence versioned 0.x.

helmfile is a **declarative spec** for deploying helm charts. With it you can:

* declare all the charts and values part of an application in one place (e.g. a git repo!)
* sync it periodically using CI to avoid skewed environments,
* have multiple environments, with different configurations,
* select/filter releases (very handy for debugging and development),
* declare common values applied to all charts,
* declare an order in which helm charts are installed[^1],
* only upgrade charts that changed (thanks to helm-diff),
* etc.

Using helmfile requires a bit of practice, especially when it comes to values [^2],
but I came to love it anyhow.

## Deploying with helmfile

Declaring our rickroller application using helmfile comes down to the following:
```yaml title="helmfile.yaml"
--8<-- "helmfile/helmfile.yaml"
```

Now that we have declaratively defined our app, we can run:

* `helmfile list` → list all the releases. Note that the *installed* column means "*it will be installed*, not "*it is already present in the cluster*"
* `helmfile template` → run `helm template` on all releases, useful for debugging
* `helmfile write-values` → compute and print the values that will be passed to each helm release, useful for debugging
* `helmfile sync` → run `helm upgrade --install` on all releases
* `helmfile apply` → look at what is already present in the cluster, and run `helm upgrade --install` only on releases that changed
* `helmfile diff` → only run the diff
* `helmfile destroy` → uninstall all releases

One of the things I use most is the ability to select specific releases when running commands:

>  `-l`, `--selector stringArray`
> 
> Only run using the releases that match labels.
> Labels can take the form of `foo=bar` or `foo!=bar`.
> A release must match all labels in a group in order to be used. Multiple groups can be specified at once.
> `"--selector tier=frontend,tier!=proxy --selector tier=backend"` will match all frontend, non-proxy releases AND all backend releases.
> The name of a release can be used as a label: `"--selector name=myrelease"`

In our example, we could thus only template the rickroller release using:
```bash
helmfile -l name=rickroller template
```

!!! warning

    The labels here refer to helmfile labels that can be added to any release in the state file.
    They have nothing to do with Kubernetes `.metadata.labels`, and are only used by internally helmfile.


This ability makes it easier for developers to work with big helmfiles, and is a big advantage against
an umbrella chart. As we discussed in the last chapter, umbrella charts are another way to pack many different
helm charts into one project. There is, however, no easy way to work on only one release with umbrella chart,
except by using `conditions` (which need to be all turned off, except for the one we are interested in).

## Using environments

There are many other features of helmfile, for example, the ability to compose state files, define environments, etc.

In our example, let's say we have three environments:

* `sandbox` (default) → we only want to deploy rickroller without any database
* `dev` → we want to deploy mongodb as well, but without any persistence (no StatefulSet)
* `prod` → we need mongodb to use persistence, it is production!

Here is the helmfile we could use (see `helmfile/helmfile-env.yaml`):

```yaml+jinja
--8<-- "helmfile/helmfile-env.yaml"
```

!!! warning

    The go templates we are using are interpreted and rendered by helmfile, they are not passed to
    helm! Thus, the `.Values` are not our usual values, they hold the `environments.values` defined in the helmfile `environments`
    section. This is quite confusing at first. So remember: we have two layers of go templates!

    To pass a template to the helm chart, we would have to write something like this:
    ```yaml
    valueAcceptingTemplate: {{ `{{ .Release.Name }}` }}
    ```

You can now deploy different flavors using the `-e <env>` flag. For example:
```bash
helmfile -e prod sync
```

[^1]: See my article [helmfile: understand (and visualize !) the order in which releases are deployed](
    https://blog.derlin.ch/helmfile-understand-and-visualize-the-order-in-which-releases-are-deployed) for more details. 
[^2]: See my article [helmfile: a simple trick to handle values intuitively](https://blog.derlin.ch/helmfile-a-simply-trick-to-handle-values-intuitively)