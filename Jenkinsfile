pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'frontend-project'
        SONAR_PROJECT_NAME = 'Frontend Project'
        SONAR_PROJECT_VERSION = '1.0'
        DOCKER_IMAGE = 'ramnivas234/frontend-project'
        DOCKER_TAG = 'latest'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub'  // Jenkins credentials ID
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/ram-nivas234/frontend-project.git', branch: 'main'
            }
        }

        stage('SonarQube Analysis') {
            tools {
                sonarQubeScanner 'SonarQubeServer'
            }
            steps {
                withSonarQubeEnv("${SonarQubeServer}") {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.projectName=${SONAR_PROJECT_NAME} \
                          -Dsonar.projectVersion=${SONAR_PROJECT_VERSION} \
                          -Dsonar.sources=. \
                          -Dsonar.language=js \
                          -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh '''
                    mkdir -p reports
                    dependency-check.sh \
                      --project "Frontend Project" \
                      --scan . \
                      --out ./reports \
                      --format HTML
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy fs . --exit-code 0 --format table --output trivy-report.txt || true
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: '**/reports/**, trivy-report.txt', allowEmptyArchive: true
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKERHUB_CREDENTIALS_ID}") {
                        dockerImage.push()
                    }
                }
            }
        }
    }
}
