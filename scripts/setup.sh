#!/bin/bash

# Tekton CI/CD Pipeline Setup Script
set -e

echo "============================================"
echo "Tekton CI/CD Pipeline Setup"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if connected to a cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to a Kubernetes cluster. Please configure kubectl."
        exit 1
    fi
    
    print_info "Prerequisites check passed!"
}

# Install Tekton Pipelines
# install_tekton() {
#     print_info "Installing Tekton Pipelines..."
#     kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
    
#     print_info "Installing Tekton Triggers..."
#     kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
    
#     print_info "Installing Tekton Dashboard (optional)..."
#     kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
    
#     print_info "Waiting for Tekton pods to be ready..."
#     kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=tekton-pipelines -n tekton-pipelines --timeout=300s
# }

# Install ArgoCD
# install_argocd() {
#     print_info "Installing ArgoCD..."
#     kubectl create namespace argocd 2>/dev/null || true
#     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
#     print_info "Waiting for ArgoCD pods to be ready..."
#     kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
# }

# Create namespaces
create_namespaces() {
    print_info "Creating namespaces..."
    # kubectl create namespace tekton-pipelines 2>/dev/null || true
    kubectl create namespace sample-app-dev 2>/dev/null || true
    kubectl create namespace sample-app-staging 2>/dev/null || true
    kubectl create namespace sample-app-prod 2>/dev/null || true
}

# Apply Tekton resources
apply_tekton_resources() {
    print_info "Applying Tekton resources..."
    
    # Apply tasks
    kubectl apply -f tekton/tasks/
    
    # Apply pipelines
    kubectl apply -f tekton/pipelines/
    
    # Apply triggers
    kubectl apply -f tekton/triggers/
}

# Create secrets
create_secrets() {
    print_info "Creating secrets..."
    
    # Docker registry secret (update with your credentials)
    print_warning "Please update the Docker registry credentials"
    kubectl create secret docker-registry docker-credentials \
        --docker-server=ghcr.io \
        --docker-username=YOUR_USERNAME \
        --docker-password=YOUR_TOKEN \
        --docker-email=YOUR_EMAIL \
        -n tekton-pipelines 2>/dev/null || print_warning "Docker credentials secret already exists"
    
    # Git credentials secret (for private repos)
    print_warning "Please update the Git credentials"
    kubectl create secret generic git-credentials \
        --from-literal=username=YOUR_USERNAME \
        --from-literal=password=YOUR_TOKEN \
        -n tekton-pipelines 2>/dev/null || print_warning "Git credentials secret already exists"
}

# Setup ArgoCD application
setup_argocd_app() {
    print_info "Setting up ArgoCD application..."
    kubectl apply -f argocd/application.yaml
}

# Get access information
get_access_info() {
    echo ""
    echo "============================================"
    echo "Setup Complete! Access Information:"
    echo "============================================"
    
    # Tekton Dashboard
    print_info "Tekton Dashboard:"
    echo "kubectl port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097"
    echo "Access at: http://localhost:9097"
    echo ""
    
    # ArgoCD
    print_info "ArgoCD Dashboard:"
    echo "kubectl port-forward -n argocd service/argocd-server 8080:443"
    echo "Access at: https://localhost:8080"
    echo ""
    echo "Get initial admin password:"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo ""
    
    # EventListener
    print_info "GitHub Webhook URL:"
    echo "kubectl get eventlistener github-listener -n tekton-pipelines"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    create_namespaces
    install_tekton
    install_argocd
    apply_tekton_resources
    create_secrets
    setup_argocd_app
    get_access_info
}

# Run main function
main "$@"