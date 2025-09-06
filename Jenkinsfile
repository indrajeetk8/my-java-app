pipeline {
    agent any
    
    environment {
        // Maven settings
        MAVEN_OPTS = '-Xmx1024m'
        // Docker registry (customize as needed)
        DOCKER_REGISTRY = 'localhost:5000' // or your registry URL
        DOCKER_IMAGE = "my-java-app"
        // Nexus credentials (store in Jenkins credentials)
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
        // Application version from pom.xml
        APP_VERSION = readMavenPom().getVersion()
    }
    
    tools {
        maven 'Maven'   // Using Jenkins suggested name
        jdk 'JDK17'     // Using Jenkins suggested name (matches what's configured)
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                script {
                    // Get commit info for build metadata
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.BUILD_TIMESTAMP = new Date().format('yyyyMMdd-HHmmss')
                }
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                bat 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                bat 'mvn test'
            }
            post {
                always {
                    // Publish test results
                    publishTestResults testsPattern: 'target/surefire-reports/*.xml'
                    // Archive test reports
                    archiveArtifacts artifacts: 'target/surefire-reports/**', allowEmptyArchive: true
                }
            }
        }
        
        stage('Code Quality Analysis') {
            parallel {
                stage('SpotBugs') {
                    steps {
                        echo 'Running SpotBugs analysis...'
                        bat 'mvn compile spotbugs:check || exit 0'
                    }
                }
                stage('Checkstyle') {
                    steps {
                        echo 'Running Checkstyle analysis...'
                        bat 'mvn checkstyle:check || exit 0'
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                bat 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    echo 'Building Docker image...'
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}")
                    
                    // Tag with latest if on main branch
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        dockerImage.tag('latest')
                    }
                    
                    // Store image ID for later use
                    env.DOCKER_IMAGE_ID = dockerImage.id
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo 'Running security scan on Docker image...'
                    // Using Trivy for vulnerability scanning (install Trivy on Jenkins agent)
                    try {
                        bat "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}"
                    } catch (Exception e) {
                        echo 'Security scan completed with warnings. Check logs for details.'
                    }
                }
            }
        }
        
        stage('Deploy to Nexus') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo 'Deploying artifact to Nexus Repository...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USERNAME',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    bat 'mvn deploy -DskipTests'
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    echo 'Pushing Docker image to registry...'
                    docker.withRegistry("http://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def image = docker.image("${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Environment') {
            parallel {
                stage('Deploy to Development') {
                    when {
                        branch 'develop'
                    }
                    steps {
                        echo 'Deploying to Development environment...'
                        script {
                            // Deploy to development environment
                            // This could be Kubernetes, Docker Swarm, or simple Docker run
                            deployToEnvironment('development')
                        }
                    }
                }
                
                stage('Deploy to Staging') {
                    when {
                        branch 'main'
                    }
                    steps {
                        echo 'Deploying to Staging environment...'
                        script {
                            deployToEnvironment('staging')
                        }
                    }
                }
            }
        }
        
        stage('Production Deployment') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY_TO_PRODUCTION == true }
                }
            }
            steps {
                script {
                    // Manual approval for production deployment
                    def userApproval = input(
                        message: 'Deploy to Production?',
                        parameters: [
                            choice(
                                name: 'DEPLOY_STRATEGY',
                                choices: ['blue-green', 'rolling', 'recreate'],
                                description: 'Select deployment strategy'
                            )
                        ]
                    )
                    
                    echo "Deploying to Production using ${userApproval} strategy..."
                    deployToEnvironment('production', userApproval)
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace...'
            // Clean up Docker images to save space
            script {
                try {
                    bat "docker rmi ${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT} || true"
                } catch (Exception e) {
                    echo 'Docker image cleanup failed, continuing...'
                }
            }
            
            // Archive important build artifacts
            archiveArtifacts artifacts: 'target/*.jar, Dockerfile, docker-compose*.yml', allowEmptyArchive: true
            
            // Clean workspace
            cleanWs()
        }
        
        success {
            echo 'Pipeline completed successfully!'
            // Send success notification
            script {
                sendNotification('SUCCESS')
            }
        }
        
        failure {
            echo 'Pipeline failed!'
            // Send failure notification
            script {
                sendNotification('FAILURE')
            }
        }
        
        unstable {
            echo 'Pipeline completed with warnings!'
            script {
                sendNotification('UNSTABLE')
            }
        }
    }
    
    parameters {
        booleanParam(
            name: 'DEPLOY_TO_PRODUCTION',
            defaultValue: false,
            description: 'Deploy to production environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip running tests'
        )
        string(
            name: 'DOCKER_TAG',
            defaultValue: '',
            description: 'Custom Docker tag (optional)'
        )
    }
}

// Helper function for deployment
def deployToEnvironment(environment, strategy = 'rolling') {
    echo "Deploying to ${environment} environment using ${strategy} strategy"
    
    switch(environment) {
        case 'development':
            // Deploy to development - could be a simple docker run
            bat """
                docker stop my-java-app-dev || true
                docker rm my-java-app-dev || true
                docker run -d --name my-java-app-dev -p 8080:8080 \
                    ${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}
            """
            break
            
        case 'staging':
            // Deploy to staging - could use docker-compose
            bat """
                docker-compose -f docker-compose.staging.yml down || true
                export IMAGE_TAG=${APP_VERSION}-${GIT_COMMIT_SHORT}
                docker-compose -f docker-compose.staging.yml up -d
            """
            break
            
        case 'production':
            // Deploy to production - more sophisticated deployment
            echo "Production deployment with ${strategy} strategy"
            // This would typically involve Kubernetes, AWS ECS, or other orchestration
            
            // Example: Update Kubernetes deployment
            // bat "kubectl set image deployment/my-java-app my-java-app=${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}"
            
            // For now, simple Docker deployment
            bat """
                docker stop my-java-app-prod || true
                docker rm my-java-app-prod || true
                docker run -d --name my-java-app-prod -p 8080:8080 \
                    --restart unless-stopped \
                    ${DOCKER_IMAGE}:${APP_VERSION}-${GIT_COMMIT_SHORT}
            """
            break
    }
}

// Helper function for notifications
def sendNotification(status) {
    def color = status == 'SUCCESS' ? 'good' : (status == 'FAILURE' ? 'danger' : 'warning')
    def message = """
        Pipeline ${status}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}
        Branch: ${env.BRANCH_NAME}
        Commit: ${env.GIT_COMMIT_SHORT}
        Build URL: ${env.BUILD_URL}
    """
    
    // Slack notification (if configured)
    try {
        slackSend(
            channel: '#deployments',
            color: color,
            message: message
        )
    } catch (Exception e) {
        echo "Slack notification failed: ${e.message}"
    }
    
    // Email notification (if configured)
    try {
        emailext(
            subject: "Pipeline ${status}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: message,
            to: '${DEFAULT_RECIPIENTS}'
        )
    } catch (Exception e) {
        echo "Email notification failed: ${e.message}"
    }
}
