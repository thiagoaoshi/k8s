# This code will create a Deployment in the Kubernetes cluster using the provided manifest.
# The manifest is a Python dictionary that represents the YAML manifest. 
# The create_deployment function loads the kubeconfig, creates a configuration, and an instance of the API class.
# It then creates the deployment using the create_namespaced_deployment method. If there is an error, it will be caught and printed.

# You can use this code as a starting point and modify it according to your requirements.
# For example, you can create separate functions for different Kubernetes resources like Services, ConfigMaps, etc.

from kubernetes import client, config
from kubernetes.client.rest import ApiException

def create_deployment(manifest):
    try:
        # Load kubeconfig and create configuration
        config.load_kubeconfig()
        configuration = client.Configuration()

        # Create an instance of the API class
        api_instance = client.AppsV1Api(client.ApiClient(configuration))

        # Create the deployment
        api_response = api_instance.create_namespaced_deployment(
            body=manifest,
            namespace='default'
        )

        print(f"Deployment created. status='{api_response.status}'")

    except ApiException as e:
        print(f"Exception when calling AppsV1Api->create_namespaced_deployment: {e}")

# Example manifest
manifest = {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "name": "nginx-deployment",
        "labels": {
            "app": "nginx"
        }
    },
    "spec": {
        "replicas": 3,
        "selector": {
            "matchLabels": {
                "app": "nginx"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app": "nginx"
                }
            },
            "spec": {
                "containers": [
                    {
                        "name": "nginx",
                        "image": "nginx:1.16.1",
                        "ports": [
                            {
                                "containerPort": 80
                            }
                        ]
                    }
                ]
            }
        }
    }
}

# Call the function to create the deployment
create_deployment(manifest)
