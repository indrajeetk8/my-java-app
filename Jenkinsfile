pipeline {
    agent any

    tools {
        maven "maven3"
    }

    environment {
        SCANNER_HOME = tool "sonar-scanner"
        NEXUS_URL = "http://localhost:8081"
        REGISTRY_URL = "docker.io"
        IMAGE_NAME = "indrajeetk8/my-java-app-image"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Check Jenkins Prerequisites') {
            steps {
                sh '''
                  echo ">>> Checking Docker version"
                  docker --version || { echo "❌ Docker not installed"; exit 1; }

                  echo ">>> Checking Docker access"
                  docker ps || { echo "❌ Jenkins user cannot run Docker"; exit 1; }
                '''
            }
        }

        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/indrajeetk8/my-java-app.git'
            }
        }

        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }

        stage('Tests') {
            steps {
                sh "mvn test"
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh "trivy fs --format table -o fs.html ."
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                      $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=bankapp \
                        -Dsonar.projectName=bankapp \
                        -Dsonar.java.binaries=target
                    '''
                }
            }
        }

        stage('Package') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('Upload to Nexus') {
            steps {
                script {
                    def version = "2.0.0-SNAPSHOT"
                    def repo = version.endsWith("SNAPSHOT") ? "maven-snapshots" : "maven-releases"

                    sh "ls -l target"

                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: 'localhost:8081',
                        groupId: 'com.example',
                        version: version,
                        repository: repo,
                        credentialsId: 'NEXUS_CRED',
                        artifacts: [[
                            artifactId: 'my-java-app',
                            classifier: '',
                            file: "target/my-java-app-${version}.jar",
                            type: 'jar'
                        ]]
                    )
                }
            }
        }

        stage('Download JAR from Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'NEXUS_CRED', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                      echo ">>> Downloading JAR from Nexus"
                      curl -u $USER:$PASS -O $NEXUS_URL/repository/maven-releases/my-java-app-2.0.0-SNAPSHOT.jar
                      ls -lh *.jar
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                  echo ">>> Building Docker image"
                  docker build -t $REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG .
                  docker images | grep $IMAGE_NAME
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials-id', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                      echo $PASS | docker login -u $USER --password-stdin $REGISTRY_URL
                      docker push $REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG_FILE')]) {
                    sh '''
                        echo ">>> Setting KUBECONFIG"
                        export KUBECONFIG=$KUBECONFIG_FILE

                        echo ">>> Deleting existing deployment (if any)..."
                        kubectl delete deployment my-java-app --ignore-not-found

                        echo ">>> Applying deployment..."
                        kubectl apply -f deployment.yml

                        echo ">>> Waiting for rollout to complete..."
                        kubectl rollout status deployment/my-java-app --timeout=60s
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG_FILE')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG_FILE
                        echo ">>> Listing pods with label app=my-java-app"
                        kubectl get pods -l app=my-java-app

                        echo ">>> Checking rollout status again just in case"
                        kubectl rollout status deployment/my-java-app --timeout=30s
                    '''
                }
            }
        }
    }
}
