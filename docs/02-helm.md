Now that rickroller is deployed, how would you:

* rename all resources to `roller` instead of `rickroller`?
* add labels to all resources to have `author=lucy`?
* delete the whole rickroller application?
* give the app to a friend so that he can deploy it on his Kubernetes cluster, which potentially
  doesn't use the same version, ingress controller, etc.?

With YAML files, there is no magic: we should go through all, make modifications, and re-apply all of them
one by one. To delete the app, we should go through many `kubectl delete` and ensure we do not forget one.
Everything is tedious: there is no logical grouping, no customization, no code reuse, nothing.

Enter [Helm](https://helm.sh)!

## What is Helm?

Helm is a **package **manager** for Kubernetes**. From [Helm homepage](https://helm.sh):

> Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.
> Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste.

## Helm Chart basics

To get started with Helm, create a new directory with the following structure:
```bash
example
├── Chart.yaml   # metadata
├── values.yaml  # parameters
└── templates    # templates
    └── ...
```

Let's add the following content:
```yaml title="Chart.yaml"
apiVersion: v2 # Helm version
name: example
description: basic example chart 
version: 0.1.0
```

```yaml title="templates/example.yaml"
some: yaml
```

Now, the directory has become a helm chart. Let's see how it works by running the following at the root of the chart directory:
```yaml
helm template .
---
# Source: example/templates/example.yaml
some: yaml
```

Okay, so a Helm chart outputs the content of the files inside the `templates` directory. So why all the fuss?
Well, the power of Helm comes from its **templating capabilities** based on Go template.
Helm has over 60 available functions. Some of them are defined by the [Go template language](https://godoc.org/text/template) itself,
and most of the others are part of the [Sprig template library](https://masterminds.github.io/sprig/).

Inside a go template, we have access to multiple contextual information coming from different sources. Let's see it in action.

Replace your template with the following content:
```yaml+jinja title="templates/example.yaml"
# "." is the root context, {{ }} denotes a go template expression
{{ . | toYaml }}
```

Let's template the chart again: `helm template .`. You should see:
```yaml
---
# Source: example/templates/example.yaml
Capabilities:
  APIVersions:
  - v1
  ...
  HelmVersion:
    git_commit: 912ebc1cd10d38d340f048efaf0abda047c3468e
    git_tree_state: clean
    go_version: go1.20.2
    version: v3.11.2
  KubeVersion:
    Major: "1"
    Minor: "26"
    Version: v1.26.0
Chart:
  IsRoot: true
  apiVersion: v2
  description: basic example chart
  name: example
  version: 0.1.0
Files: {}
Release:
  IsInstall: true
  IsUpgrade: false
  Name: release-name
  Namespace: test
  Revision: 1
  Service: Helm
Subcharts: {}
Template:
  BasePath: example/templates
  Name: example/templates/example.yaml
Values: {}
```

To break it down, this is everything you can query from a go template:

* `.Capabilities`: the API resources available in the cluster you are currently connected to.
  This let's you customize your output depending on the k8s cluster (using `if/else` etc.)
* `.Chart`: information from your `Chart.yaml` file, including the current version of the chart, etc.
* `.Files`: additional files in the helm chart directory, that you could read and use in your templates
* `.Release`: the name, namespace etc. of the helm chart *as it is being installed*
* `.Subcharts`: helm charts can include other charts (we will talk about this later)
* `.Template`: template files information
* `.Values`: content of `values.yaml`

The most useful are `.Release` and `.Values`. Whatever you put in your `values.yaml` will be available
in the templates. They act as *the parameters* to the templates and let you customize the helm chart at
install time. 

To better understand the `.Values`, add this:
```yaml title="values.yaml"
hello: world
```
Now, run the following two commands:
```bash
helm template . | tail -2
```
``` { .yaml .no-copy }
Values:
  hello: world
```
```bash
helm template . --set hello='Fribourg!' | tail -2
```
``` { .yaml .no-copy }
Values:
  hello: Fribourg!
```

Helm charts are thus a bunch of templates that should output valid Kubernetes Manifests files (as YAML)
based on the parameters initially defined in `values.yaml` but overridable from the command line.

Valus are overridable from the command line using `--set`, or from a YAML file using `--values <file>`.
The content of the provided file will be *merged* with the content of the `values.yaml`, with precedence
to the former.

!!! warning ""
    Be careful! YAML merge works great with dictionaries, but not with lists: list are
    completely _replaced_, the items are not merged.

??? note "A more accurate example"

    To have a valid helm chart, you could replace the content of `templates/example.yaml` with the following:
    ```yaml+jinja
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: {{ .Release.Name }}
    spec:
      replicas: {{ .Values.replicas | default 1 }}
      selector:
        matchLabels: 
          app: {{ .Release.Name }}
      template:
        metadata:
          labels:
            app: {{ .Release.Name }}
        spec:
          containers:
            - image: derlin/rickroller:{{ .Values.tag | default "latest" }}
              name: {{ .Release.Name }}
              ports:
                - containerPort: 8080
    ```

    You can now play with it, setting e.g. the values `--set replicas=2` or `--set tag=1.0.0`.

## Working with a Helm Chart

Of course, real helm charts are quite complex and necessitate getting acquainted with the go template
syntax. To get started, you can try using the `helm create` function.
For the next examples, I already created a Helm chart (using `helm create` as a base) for rickroller
that you can find in the `helm/rickroller` directory. Assume all the next commands are run from there.

!!! tip

    I suggest you create a new namespace for your tests with Helm.

Now that rickroller is packaged with helm, we can install it in our cluster using:
```bash
helm install roller .
```
``` { .bash .no-copy }
Release "roller" does not exist. Installing it now.
NAME: roller
LAST DEPLOYED: Mon Apr 17 15:43:16 2023
NAMESPACE: example
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  http:///roller(/|$)(.*)
```

Now, you can run the following:

* `helm list` → roller is installed
* `helm upgrade roller . --set replicas=2` → scale to 2
* `helm rollback roller` → we are back to the first revision with one replica
* `helm history roller` → we have 3 revisions: one install, one upgrade, and a rollback
* `helm uninstall roller` → completely uninstalls everything.

You want to not use an ingress, but a service of type `LoadBalancer` (as we did previously) instead?
Easy:
```bash
helm upgrade --install roller . --set ingress.enabled=false --set service.type=LoadBalancer
```

## Using charts from a repository

So far, we used a local chart. Let's use helm now to deploy MongDB from bitnami.
First, add the repo so your machine knows how to fetch bitnami charts:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Now, install mongodb with an initial database, username and password:
```bash
helm upgrade --install mongodb bitnami/mongodb --version 13.9.1 \
    --set architecture=standalone \
    --set 'auth.usernames[0]=myuser' --set 'auth.passwords[0]=mypass' --set 'auth.databases[0]=mydb' \
    --set persistence.enabled=false
```

??? tip "Using persistence"

    Since we installed longhorn, we can turn on persistence if we want to:
    ```bash
    helm upgrade --install mongodb bitnami/mongodb --version 13.9.1 \
    --set architecture=standalone --set 'auth.usernames[0]=myuser' --set 'auth.passwords[0]=mypass' --set 'auth.databases[0]=mydb' \
    --set persistence.enabled=true --set persistence.storageClass=longhorn --set persistence.size=1Gi
    ```

We can now deploy/upgrade rickroller and ask it to use mongodb:
```bash
helm upgrade --install rickroller . --set env.DATABASE_URL='mongodb://myuser:mypass@mongodb/mydb'
```

## Using subcharts

It is also possible to make mongodb *part of* the rickroller Helm chart. The advantage is that we only need one
helm command to get both. The disadvantage? They are treated as a whole: we cannot update or uninstall one without the
other.

??? tip "Adding mongodb as a subchart"

    First, add the following to `Chart.yaml`:
    ```yaml
    dependencies:
      - name: mongodb
        version: 13.9.1
        repository: "@bitnami"
    ```

    Next, add the following to `values.yaml`:
    ```yaml
    mongodb:
    auth:
      rootPassword: root
      usernames: [myuser]
      passwords: [mypass]
      databases: [mydb]
    persistence:
      enabled: false
      storageClass: longhorn
      size: 1Gi
    
    # ...

    env:
      # ...
      DATABASE_URL: mongodb://myuser:mypass@{{ .Release.Name }}-mongodb/mydb
    ```

    Done! Run the following command once and you are good to go:
    ```bash
    # update the dependencies
    # this will create a folder charts/ with a tar of the mongodb chart
    helm dependency update
    ```

A chart can have any number of subcharts, making it possible to treat a large and
complex project as a whole. In this case, we call the root helm chart an
umbrella chart.

The **umbrella chart** is responsible for creating the namespace and the global
components such as the network policies, and each microservice is included as
a dependency.

It is even possible to reuse the same generic helm chart for multiple dependencies/microservice.
For this, we only have one subchart directory (only one chart under `charts`),
but reference it multiple times in the dependencies. This generic subchart is then
configured with different values depending on the microservice.

Here is an example:

```yaml title="Chart.yaml"
apiVersion: v2
name: my-umbrella-chart
description: A Helm umbrella chart for deploying my application.
type: umbrella
version: 1.0.0

# the name reference the chart (templates),
# the alias is the name we give for this instance of the templates
dependencies:
  - alias: service-1
    name: generic-chart
    version: 1.0.0
    condition: service-1.enabled # we can even use conditions!

  - alias: service-N
    name: generic-chart
    version: 1.0.0
    condition: service-N.enabled
```

```yaml title="values.yaml"
service-1:
    enabled: true
    port: 8080
    env:
      SERVICE_1_CONTEXT: bar
    # ...

service-N:
    enabled: true
    port: 80
    ingress:
        enabled: true
        host: service-n.example.com
    # ...
```