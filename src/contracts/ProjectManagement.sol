// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProjectManagement {
    struct Project {
        string name;
        uint256 teamSize;
        uint256 taskCount;
        bool isCompleted;
    }

    struct Task {
        string description;
        address assignedTo;
        uint256 deadline;
        uint256 reward;
        bool completed;
        bool verified;
    }

    address public admin;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => address[]) public teamMembers;
    mapping(uint256 => uint256[]) public taskIds;
    mapping(uint256 => mapping(uint256 => Task)) public tasks;

    event ProjectCreated(uint256 indexed projectId, string name, address[] teamMembers);
    event TaskCreated(uint256 indexed projectId, uint256 indexed taskId, string description, address assignedTo, uint256 reward);
    event TaskCompleted(uint256 indexed projectId, uint256 indexed taskId);
    event ProjectVerified(uint256 indexed projectId);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyProjectMember(uint256 projectId) {
        bool isMember = false;
        for (uint i = 0; i < teamMembers[projectId].length; i++) {
            if (teamMembers[projectId][i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Only project members can call this function");
        _;
    }

    function createProject(uint256 projectId, string memory name, address[] memory members) public onlyAdmin {
        require(projects[projectId].teamSize == 0, "Project ID already exists");
        
        projects[projectId] = Project({
            name: name,
            teamSize: members.length,
            taskCount: 0,
            isCompleted: false
        });
        
        teamMembers[projectId] = members;
        
        emit ProjectCreated(projectId, name, members);
    }

    function createTask(
        uint256 projectId,
        uint256 taskId,
        string memory description,
        address assignedTo,
        uint256 deadline,
        uint256 reward
    ) public onlyAdmin {
        require(projects[projectId].teamSize > 0, "Project does not exist");
        require(tasks[projectId][taskId].assignedTo == address(0), "Task ID already exists");
        
        tasks[projectId][taskId] = Task({
            description: description,
            assignedTo: assignedTo,
            deadline: deadline,
            reward: reward,
            completed: false,
            verified: false
        });
        
        taskIds[projectId].push(taskId);
        projects[projectId].taskCount++;
        
        emit TaskCreated(projectId, taskId, description, assignedTo, reward);
    }

    function completeTask(uint256 projectId, uint256 taskId) public onlyProjectMember(projectId) {
        require(projects[projectId].teamSize > 0, "Project does not exist");
        require(tasks[projectId][taskId].assignedTo == msg.sender, "Only assigned user can complete task");
        require(!tasks[projectId][taskId].completed, "Task already completed");
        require(!tasks[projectId][taskId].verified, "Task already verified");
        
        tasks[projectId][taskId].completed = true;
        
        emit TaskCompleted(projectId, taskId);
    }

    function verifyProject(uint256 projectId) public payable onlyAdmin {
        require(projects[projectId].teamSize > 0, "Project does not exist");
        require(!projects[projectId].isCompleted, "Project already completed");
        
        uint256 totalReward = 0;
        for (uint i = 0; i < taskIds[projectId].length; i++) {
            uint256 taskId = taskIds[projectId][i];
            if (!tasks[projectId][taskId].verified) {
                require(tasks[projectId][taskId].completed, "All tasks must be completed");
                tasks[projectId][taskId].verified = true;
                totalReward += tasks[projectId][taskId].reward;
            }
        }
        
        require(msg.value >= totalReward, "Insufficient reward amount");
        
        for (uint i = 0; i < taskIds[projectId].length; i++) {
            uint256 taskId = taskIds[projectId][i];
            if (tasks[projectId][taskId].verified) {
                (bool success, ) = tasks[projectId][taskId].assignedTo.call{value: tasks[projectId][taskId].reward}("");
                require(success, "Transfer failed");
            }
        }
        
        projects[projectId].isCompleted = true;
        
        emit ProjectVerified(projectId);
    }

    function getProjectInfo(uint256 projectId) public view returns (Project memory) {
        return projects[projectId];
    }

    function getTeamMembers(uint256 projectId) public view returns (address[] memory) {
        return teamMembers[projectId];
    }

    function getTaskIds(uint256 projectId) public view returns (uint256[] memory) {
        return taskIds[projectId];
    }

    function getTask(uint256 projectId, uint256 taskId) public view returns (Task memory) {
        return tasks[projectId][taskId];
    }
} 