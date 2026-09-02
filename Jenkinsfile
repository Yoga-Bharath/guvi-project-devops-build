// ---- Jenkinsfile ----
// Multibranch pipeline: builds a Docker image, pushes it to the correct
// Docker Hub repo (dev vs prod) based on branch, then deploys it to the
// EC2 server.
//
// Required Jenkins credentials (Manage Jenkins > Credentials):
//   dockerhub-creds  -> Username/Password (or access token) for Docker Hub
//   ec2-ssh-key      -> SSH Username with private key for the EC2 instance
//
// Required Jenkins plugins: Docker Pipeline, SSH Agent, GitHub Integration
// Required job type: Multibranch Pipeline (so BRANCH_NAME is available and
// both dev + master branches are auto-discovered and build on push).

pipeline {
  agent any

  environment {
    DOCKERHUB_CREDS = credentials('dockerhub-credentials')
    DOCKERHUB_USER  = 'yogabharath'
    EC2_HOST        = 'ubuntu@172.31.12.161'
    SSH_CREDS       = 'ec2-ssh-key'
  }

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          chmod +x build.sh deploy.sh
          BRANCH="${BRANCH_NAME}" DOCKERHUB_USER="${DOCKERHUB_USER}" IMAGE_TAG="${GIT_COMMIT}" ./build.sh
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          . ./.last_build.env
          echo "${DOCKERHUB_CREDS_PSW}" | docker login -u "${DOCKERHUB_CREDS_USR}" --password-stdin
          docker push "${IMAGE_NAME}:${IMAGE_TAG}"
          docker push "${IMAGE_NAME}:latest"
          docker logout
        '''
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent(credentials: ["${SSH_CREDS}"]) {
          sh '''
            . ./.last_build.env
            scp -o StrictHostKeyChecking=no deploy.sh "${EC2_HOST}:/home/ubuntu/deploy.sh"
            ssh -o StrictHostKeyChecking=no "${EC2_HOST}" \
              "chmod +x deploy.sh && DOCKERHUB_USER=${DOCKERHUB_USER} REPO=${REPO} IMAGE_TAG=latest ./deploy.sh"
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
    }
    success {
      echo "Pipeline succeeded for branch ${env.BRANCH_NAME}"
    }
    failure {
      echo "Pipeline FAILED for branch ${env.BRANCH_NAME}"
    }
  }
}
