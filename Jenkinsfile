// ---- Jenkinsfile ----
// Multibranch pipeline: builds a Docker image, pushes it to the correct
// Docker Hub repo (dev vs prod) based on branch, then deploys it locally
// on the Jenkins EC2 server.
//

pipeline {
  agent any

  environment {
    DOCKERHUB_CREDS = credentials('dockerhub-creds')
    DOCKERHUB_USER  = 'yogabharath'
  }

  options {
    disableConcurrentBuilds()
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
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
          echo "${DOCKERHUB_CREDS_PSW}" | docker login \
            -u "${DOCKERHUB_CREDS_USR}" \
            --password-stdin
          docker push "${IMAGE_NAME}:${IMAGE_TAG}"
          docker push "${IMAGE_NAME}:latest"
        '''
        // NOTE: no "docker logout" here anymore — Deploy stage below needs to
        // stay authenticated to pull from the PRIVATE devops-build-prod repo.
        // We log out exactly once, in post{always{}}, after Deploy has run.
      }
    }

    stage('Deploy locally') {
      steps {
        sh '''
          . ./.last_build.env
          chmod +x deploy.sh
          DOCKERHUB_USER="${DOCKERHUB_USER}" \
          REPO="${REPO}" \
          IMAGE_TAG=latest \
          ./deploy.sh
        '''
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
