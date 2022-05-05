node {
    def release = '7_7_20220228'
    def nonProdEnvs = ['dev', 'sit']
    def branchName
    def pullRequest
    def targetEnvironment
    def dateTimeSignature
    def imageTag
    def imageRepository

    stage('Initialize') {
        branchName = BRANCH_NAME
        echo "checking if it's a pull request branch!"
        if (branchName.toUpperCase().startsWith("PR-")) {
            echo "found pull request '${branchName}', so targetting it to the 'DEV' environment!!!"
            pullRequest = branchName.substring(branchName.lastIndexOf("-") + 1)
            echo "Pull request is   ========================================>  ${pullRequest}."
        } else {
            echo "${branchName} is not a pull request."
        }
    }

    stage("Checkout Code (${pullRequest ? 'PR-' + pullRequest : branchName})") {
        if (pullRequest) {
            echo "Checking out pull request '${branchName}'"
            try {
                git branch: '${BRANCH_NAME}', credentialsId: 'GITHUB_PERSONAL_ACCESS_TOKEN', url: 'https://github.com/gitlabzz/apim-base-77.git'
            } catch (exception) {
                sh '''
                    git fetch origin +refs/pull/''' + pullRequest + '''/merge
                    git checkout FETCH_HEAD
                '''
                branchName = "dev"
                echo "targeting build for pull request ${pullRequest} to '${branchName}' environment"
            }
            echo "Check out for pull request '${BRANCH_NAME}' is successfully completed!"

        } else {
            echo "Checking out branch '${BRANCH_NAME}'"
            git branch: '${BRANCH_NAME}', credentialsId: 'GITHUB_PERSONAL_ACCESS_TOKEN', url: 'https://github.com/gitlabzz/apim-base-77.git'
            echo "Check out for '${BRANCH_NAME}' is successfully completed!"
        }
    }

    stage('Remove Existing Images') {
        sh "docker system prune -f"
        echo "Successfully completed 'docker system prune -f' command"
        try {
            sh "docker rmi -f \$(docker images -aq)"
            echo "Successfully completed 'docker rmi -f \$(docker images -aq)' command"
        } catch (exception) {
            echo "Couldn't complete docker rmi, probably no images for deletion."
        }
        echo "Cleared existing and dangling images, ready for build."
    }

    stage('Build Base Image') {
        withDockerRegistry(credentialsId: 'HARBOR.CREDENTAILS', url: "${env.HARBOR_URL}") {

            targetEnvironment = BRANCH_NAME.toLowerCase()
            echo "Building for branch: '${BRANCH_NAME}'"

            if (targetEnvironment.equals('main')) {
                targetEnvironment = 'prod'
                echo "Branch '${BRANCH_NAME}' is going to be treated as 'PROD' branch"
            }

            if (targetEnvironment.equalsIgnoreCase('dev')) {
                imageTag += "_SNAPSHOT"
                imageRepository = "_snapshot"
            } else {
                imageTag += "_RELEASE"
                imageRepository = "_release"
            }
            sh "./build_base_image.sh ${release} ${env.HARBOR_FQDN} ${imageRepository}"
            echo "Build Completed for branch: '${targetEnvironment}' Image Created: ${release}_${dateTimeSignature} Using Release: ${release}"
        }
    }

    stage('Create Latest Tag') {
        sh "docker tag ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:${imageTag} ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:latest"
        echo "Executed 'docker tag ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:${imageTag} ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:latest'"
        echo "Tag '${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:latest' created from '${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:${imageTag}'"
    }

    stage('Push Release Tag') {
        withDockerRegistry(credentialsId: 'HARBOR.CREDENTAILS', url: "${env.HARBOR_URL}") {
            sh "docker push ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:${imageTag}"
            echo "Executed 'docker push ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:${imageTag}'"
        }
    }

    stage('Push Latest Tag') {
        withDockerRegistry(credentialsId: 'HARBOR.CREDENTAILS', url: "${env.HARBOR_URL}") {
            sh "docker push ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:latest"
            echo "Executed 'docker push ${env.HARBOR_FQDN}/apim/apim_base${imageRepository}:latest'"
        }
    }

    stage('Docker Logout') {
        sh 'docker logout'
        echo "Executed 'docker logout'"
    }


}