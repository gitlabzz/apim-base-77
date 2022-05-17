node('APIM-Python-Docker') {
    def release = '7_7_20220228'
    def nonProdSITEnvs = ['dev', 'sit']
    def nonProdUATEnvs = ['uat']
    def branchName
    def pullRequest
    def targetEnvironment
    def dateTimeSignature
    def imageTag
    def harborProjectName = "/apim"
    def imageName = "/apim_base"
    def approvalStatus

    stage('Initialize') {
        branchName = BRANCH_NAME
        echo "checking if it's a pull request branch!"
        if (branchName.toUpperCase().startsWith("PR-")) {
            echo "found pull request '${branchName}', so targetting it to the 'SIT' environment!!!"
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
                git branch: '${BRANCH_NAME}', credentialsId: 'gitlab.vv0053.userid.password', url: 'https://github.com/gitlabzz/apim-base-77.git'
            } catch (exception) {
                sh '''
                    git fetch origin +refs/pull/''' + pullRequest + '''/merge
                    git checkout FETCH_HEAD
                '''
                branchName = "sit"
                echo "targeting build for pull request ${pullRequest} to '${branchName}' environment"
            }
            echo "Check out for pull request '${BRANCH_NAME}' is successfully completed!"

        } else {
            echo "Checking out branch '${BRANCH_NAME}'"
            git branch: '${BRANCH_NAME}', credentialsId: 'gitlab.vv0053.userid.password', url: 'https://github.com/gitlabzz/apim-base-77.git'
            echo "Check out for '${BRANCH_NAME}' is successfully completed!"
        }
    }

    stage('Generate Image Tag') {
        dateTimeSignature = new java.text.SimpleDateFormat("YYYYMMdd").format(new Date())
        echo "The datetime signature for build is: ${dateTimeSignature}"
        dateTimeSignature += "_${env.BUILD_NUMBER}"
        echo "The datetime signature along with build number is: ${dateTimeSignature}"
        imageTag = "${release}_${dateTimeSignature}"
        echo "The Image tag is going to be: ${imageTag}"
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

    stage('Build APIM Base Image') {
        withDockerRegistry(credentialsId: 'harbor.vv0053.userid.password', url: "${env.HARBOR_URL}") {

            targetEnvironment = BRANCH_NAME.toLowerCase()
            echo "Building for branch: '${BRANCH_NAME}'"

            if (targetEnvironment.equals('main')) {
                targetEnvironment = 'prod'
                echo "Branch '${BRANCH_NAME}' is going to be treated as 'PROD' branch"
            }

            if (nonProdSITEnvs.contains(targetEnvironment)) {
                harborProjectName += "_sit"
            } else if (nonProdUATEnvs.contains(targetEnvironment)) {
                harborProjectName += "_uat"
            }

            sh "./build_base_image.sh ${imageTag} ${env.HARBOR_FQDN} ${harborProjectName} ${imageName}"
            echo "Build Completed for branch: '${BRANCH_NAME}' Image Created: ${env.HARBOR_FQDN}${imageName}${imageTag} Using Release: ${release}"
        }
    }

    stage('Approve/ Decline Image Push') {
        if (nonProdSITEnvs.contains(targetEnvironment)) {
            echo "Approval not required for '${nonProdSITEnvs}' environment, this build is for '${targetEnvironment}'"
            approvalStatus = true
        } else {
            def approvalStatusInput = input message: 'Please approve to push image to Harbor repository', parameters: [choice(name: 'approvalStatus', choices: ['Approved', 'Declined'])]
            echo "approvalStatusInput: ${approvalStatusInput}"
            approvalStatus = approvalStatusInput.equalsIgnoreCase('Approved') ? true : false
            echo "approvalStatus: ${approvalStatus}"
        }
    }

    stage('Create Latest Tag') {
        sh "docker tag ${env.HARBOR_FQDN}${harborProjectName}${imageName}:${imageTag} ${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest"
        echo "Executed 'docker tag ${env.HARBOR_FQDN}${harborProjectName}${imageName}:${imageTag} ${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest'"
        echo "Tag '${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest' created from '${env.HARBOR_FQDN}${harborProjectName}${imageName}:${imageTag}'"
    }

    stage('Push Release Tag') {
        if (approvalStatus) {
            withDockerRegistry(credentialsId: 'harbor.vv0053.userid.password', url: "${env.HARBOR_URL}") {
                sh "docker push ${env.HARBOR_FQDN}${harborProjectName}${imageName}:${imageTag}"
                echo "Executed 'docker push ${env.HARBOR_FQDN}${harborProjectName}${imageName}:${imageTag}'"
            }
        } else {
            echo "Not pushing to Harbor as '${env.HARBOR_FQDN}${imageName}${imageRepository}:${imageTag}' it's not approved."
        }

    }

    stage('Push Latest Tag') {
        if (approvalStatus) {
            withDockerRegistry(credentialsId: 'harbor.vv0053.userid.password', url: "${env.HARBOR_URL}") {
                sh "docker push ${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest"
                echo "Executed 'docker push ${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest'"
            }
        } else {
            echo "Not pushing to Harbor as '${env.HARBOR_FQDN}${harborProjectName}${imageName}:latest' it's not approved."
        }
    }

    stage('Docker Logout') {
        sh 'docker logout'
        echo "Executed 'docker logout'"
    }
}