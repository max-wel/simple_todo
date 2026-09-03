pipeline {
    agent any

    stages {
        stage('Run tests') {
            agent {
                docker {
                    image 'maven:3.9.16-eclipse-temurin-25'
                    args: '-v '
                    reuseNode true
                }
            }
            steps {
                echo 'Testing..'
                sh 'mvn test'
           }

        }
        stage('test') {
            steps {
                echo 'Testing'
            }
        }
        stage('deploy') {
            steps {
                echo 'Deploying'
            }
        }
    }
}
