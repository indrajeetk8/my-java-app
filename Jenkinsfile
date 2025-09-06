pipeline {
    agent any
    
    environment {
        MAVEN_OPTS = '-Xmx1024m'
    }
    
    tools {
        maven 'Maven3'  // Using Jenkins suggested name
        jdk 'JDK17'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = bat(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    // Read version from pom.xml
                    def pom = readFile('pom.xml')
                    def version = (pom =~ /<version>([^<]+)<\/version>/)[0][1]
                    env.APP_VERSION = version
                    echo "Application version: ${env.APP_VERSION}"
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
                    publishTestResults testsPattern: 'target/surefire-reports/*.xml'
                    archiveArtifacts artifacts: 'target/surefire-reports/**', allowEmptyArchive: true
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
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
