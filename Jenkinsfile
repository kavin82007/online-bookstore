pipeline {
    agent any

    environment {
        IMAGE = 'blackwolf82007/online-bookstore'
        TAG   = "build-${env.BUILD_NUMBER}"
        APP   = 'online-bookstore'
        SMOKE = "bookstore-smoke-${env.BUILD_NUMBER}"
    }

    stages {

        stage('Clone Code') {
            steps {
                checkout scm
            }
        }

        stage('Gate 1: Content Tests') {
            steps {
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File tests\\content-tests.ps1'
            }
        }

        stage('Gate 2: Security Scan') {
            steps {
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File tests\\security-scan.ps1'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t %IMAGE%:%TAG% ."
            }
        }

        stage('Gate 3: Smoke Test Container') {
            steps {
                bat "docker run -d --name %SMOKE% -p 8090:80 %IMAGE%:%TAG%"
                powershell '''
                    Start-Sleep -Seconds 3
                    $r = Invoke-WebRequest -Uri http://localhost:8090 -UseBasicParsing
                    if ($r.StatusCode -ne 200 -or $r.Content -notmatch "Online Bookstore") {
                        Write-Host "Smoke test FAILED"
                        exit 1
                    }
                    Write-Host "Smoke test passed - HTTP 200 and bookstore page served"
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    bat 'echo %DH_PASS%| docker login -u %DH_USER% --password-stdin'
                    bat "docker push %IMAGE%:%TAG%"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    powershell "(Get-Content deployment.yaml) -replace '${env.IMAGE}:.*', '${env.IMAGE}:${env.TAG}' | Set-Content deploy-ci.yaml"
                    bat "kubectl apply -f deploy-ci.yaml"
                    bat "kubectl annotate deployment/%APP% kubernetes.io/change-cause=\"Jenkins build %BUILD_NUMBER% - %TAG%\" --overwrite"
                }
            }
        }

        stage('Gate 4: Verify Rollout / Auto Rollback') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        try {
                            bat "kubectl rollout status deployment/%APP% --timeout=90s"
                        } catch (err) {
                            echo "ROLLOUT FAILED for ${env.TAG} - rolling back to previous stable release"
                            bat "kubectl rollout undo deployment/%APP%"
                            bat "kubectl rollout status deployment/%APP% --timeout=90s"
                            bat "kubectl rollout history deployment/%APP%"
                            error("Faulty release ${env.TAG} was rolled back automatically")
                        }
                    }
                }
            }
        }

        stage('Verify Application') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    bat "kubectl get deployment %APP%"
                    bat "kubectl get pods -l app=%APP%"
                    bat "kubectl get svc online-bookstore-service"
                }
                bat "curl -sf http://localhost:30081 -o NUL && echo Bookstore is reachable on NodePort 30081"
            }
        }
    }

    post {
        always {
            bat "docker rm -f %SMOKE% || exit 0"
            bat 'docker logout'
        }
    }
}