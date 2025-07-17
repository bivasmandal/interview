# DevOps Interview Environment Post-Create Setup Script
echo "🚀 DevOps interview environment..."

 Create AWS OIDC authentication script
cat > ~/interview-workspace/scripts/aws-oidc-auth.sh << 'EOF'
#!/bin/bash
# AWS OIDC Authentication for GitHub Codespaces

set -e

# Configuration
AWS_REGION="me-south-1"
AWS_ROLE_ARN="arn:aws:iam::311460872330:role/GitHubCodespaceRole"
AWS_SESSION_NAME="codespace-session"

echo "🔐 Setting up AWS OIDC authentication..."

# Check if we're in a GitHub Codespace
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ This script must be run in a GitHub Codespace"
    exit 1
fi

# Get the OIDC token
OIDC_TOKEN=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
    "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r '.value')

if [ "$OIDC_TOKEN" == "null" ] || [ -z "$OIDC_TOKEN" ]; then
    echo "❌ Failed to get OIDC token"
    exit 1
fi

# Assume role with web identity
echo "🔑 Assuming AWS role..."
CREDENTIALS=$(aws sts assume-role-with-web-identity \
    --role-arn "$AWS_ROLE_ARN" \
    --role-session-name "$AWS_SESSION_NAME" \
    --web-identity-token "$OIDC_TOKEN" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

if [ $? -ne 0 ]; then
    echo "❌ Failed to assume role"
    exit 1
fi

# Parse credentials
read -r ACCESS_KEY SECRET_KEY SESSION_TOKEN <<< "$CREDENTIALS"

# Set environment variables
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"
export AWS_DEFAULT_REGION="$AWS_REGION"

# Save to profile for persistence
aws configure set aws_access_key_id "$ACCESS_KEY"
aws configure set aws_secret_access_key "$SECRET_KEY"
aws configure set aws_session_token "$SESSION_TOKEN"
aws configure set region "$AWS_REGION"

echo "✅ AWS authentication successful!"
echo "🎯 You can now use AWS CLI and Terraform with temporary credentials"

# Verify authentication
echo "📋 Current AWS identity:"
aws sts get-caller-identity

EOF

chmod +x ~/interview-workspace/scripts/aws-oidc-auth.sh

# Create README with instructions
cat > ~/interview-workspace/README.md << 'EOF'
# DevOps Interview Environment

Welcome to your DevOps interview environment! This workspace comes pre-configured with:

## Pre-installed Tools
- ✅ Terraform
- ✅ AWS CLI
- ✅ kubectl
- ✅ Helm
- ✅ Docker
- ✅ Git

## AWS Authentication (OIDC)

This environment supports secure AWS authentication via OIDC (no long-lived credentials needed).

### Setup AWS Authentication:
```bash
# Run the OIDC authentication script
./scripts/aws-oidc-auth.sh

# Verify authentication
aws sts get-caller-identity
```