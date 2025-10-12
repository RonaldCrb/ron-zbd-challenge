#!/bin/bash

# Security Group Test Script
# This script helps verify that Prometheus can only access the /metrics endpoint
# when security groups are properly configured

set -e

echo "🔒 Testing Security Group Configuration"
echo "======================================"

# Get instance IPs from Terraform output
INSTANCE_A_IP=$(cd terraform && terraform output -raw instance_a_public_ip)
INSTANCE_B_IP=$(cd terraform && terraform output -raw instance_b_public_ip)

echo "Instance A (API Server): $INSTANCE_A_IP"
echo "Instance B (Prometheus): $INSTANCE_B_IP"
echo ""

# Test 1: Verify API server health endpoint is accessible
echo "🧪 Test 1: API Health Endpoint Accessibility"
echo "Testing: http://$INSTANCE_A_IP:8080/health"
if curl -f -s http://$INSTANCE_A_IP:8080/health > /dev/null; then
    echo "✅ API health endpoint is accessible"
else
    echo "❌ API health endpoint is not accessible"
fi
echo ""

# Test 2: Verify API metrics endpoint is accessible
echo "🧪 Test 2: API Metrics Endpoint Accessibility"
echo "Testing: http://$INSTANCE_A_IP:8080/metrics"
if curl -f -s http://$INSTANCE_A_IP:8080/metrics > /dev/null; then
    echo "✅ API metrics endpoint is accessible"
else
    echo "❌ API metrics endpoint is not accessible"
fi
echo ""

# Test 3: Verify Prometheus UI is accessible
echo "🧪 Test 3: Prometheus UI Accessibility"
echo "Testing: http://$INSTANCE_B_IP:9090"
if curl -f -s http://$INSTANCE_B_IP:9090 > /dev/null; then
    echo "✅ Prometheus UI is accessible"
else
    echo "❌ Prometheus UI is not accessible"
fi
echo ""

# Test 4: Test from Prometheus instance to API metrics
echo "🧪 Test 4: Prometheus to API Metrics (Internal Test)"
echo "This test should be run from the Prometheus instance:"
echo "ssh -i your-key.pem ec2-user@$INSTANCE_B_IP"
echo "curl -f http://$INSTANCE_A_IP:8080/metrics"
echo ""

# Instructions for manual testing
echo "📋 Manual Testing Instructions:"
echo "================================"
echo ""
echo "1. SSH to Prometheus instance (Instance B):"
echo "   ssh -i your-key.pem ec2-user@$INSTANCE_B_IP"
echo ""
echo "2. Test Prometheus can scrape API metrics:"
echo "   curl -f http://$INSTANCE_A_IP:8080/metrics"
echo ""
echo "3. Test Prometheus can access API health:"
echo "   curl -f http://$INSTANCE_A_IP:8080/health"
echo ""
echo "4. If security groups are misconfigured:"
echo "   - Remove prometheus_security_group_id from instance_a module"
echo "   - Run: terraform apply"
echo "   - Test again - Prometheus should NOT be able to access /metrics"
echo ""
echo "5. To verify security group rules:"
echo "   aws ec2 describe-security-groups --group-ids \$(terraform output -raw instance_a_security_group_id)"
echo ""

# Display current security group configuration
echo "🔍 Current Security Group Configuration:"
echo "========================================"
cd terraform
echo "Instance A Security Group ID: $(terraform output -raw instance_a_security_group_id 2>/dev/null || echo 'Not found')"
echo "Instance B Security Group ID: $(terraform output -raw instance_b_security_group_id 2>/dev/null || echo 'Not found')"
