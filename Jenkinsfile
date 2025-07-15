pipeline {
    agent any

    stages {
        stage('Git Checkout') {
            steps {
                echo 'Cloning the code'
                git branch: 'main', url: 'https://github.com/ram-nivas234/frontend-project.git'
            }
        }
        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("sonarqube") {
                    sh "${tool('sonarqube')}/bin/sonar-scanner"
                }
            }
        }
        stage('Quality Gate Check') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Docker Build') {
            steps {
                echo 'Building the Docker image'
                sh 'whoami'
                sh 'docker build -t ramnivas23/frontend-project .'
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Pushing the Docker image to Docker Hub'
                sh 'docker push ramnivas23/frontend-project'
            }
        }
    }
}
