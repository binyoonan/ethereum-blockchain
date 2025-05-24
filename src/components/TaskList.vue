<template>
  <div class="task-list-container">
    <div v-if="isLoading" class="loading">Loading tasks...</div>
    <div v-else class="task-list">
      <div v-for="task in tasks" :key="task.id" class="task-item">
        <div class="task-header">
          <h4>{{ task.description }}</h4>
          <span class="task-id">Task ID: {{ task.id }}</span>
        </div>
        <div class="task-details">
          <div class="task-info">
            <p><strong>Assigned to:</strong> {{ shortAddress(task.assignedTo) }}</p>
            <p><strong>Deadline:</strong> {{ formatDate(task.deadline) }}</p>
            <p><strong>Reward:</strong> {{ formatEther(task.reward) }} ETH</p>
          </div>
          <div class="task-status">
            <span :class="['status-badge', task.status.toLowerCase()]">
              {{ task.status }}
            </span>
            <button
              v-if="task.isAssignedToMe && !task.completed && !task.verified"
              class="btn btn-secondary"
              @click="completeTask(task)"
              :disabled="isCompleting"
            >
              Complete Task
            </button>
          </div>
        </div>
      </div>
      <div v-if="canVerifyProject" class="verify-project">
        <button
          class="btn btn-primary"
          @click="verifyProject"
          :disabled="isVerifying"
        >
          {{ isVerifying ? 'Verifying...' : 'Verify Project & Pay Rewards' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../contracts/config';

const props = defineProps({
  projectId: {
    type: String,
    required: true
  }
});

const tasks = ref([]);
const isLoading = ref(true);
const isCompleting = ref(false);
const isVerifying = ref(false);
const projectInfo = ref(null);

const shortAddress = (addr) => {
  if (!addr) return '';
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
};

const formatDate = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString();
};

const formatEther = (wei) => {
  return ethers.utils.formatEther(wei);
};

const canVerifyProject = computed(async () => {
  if (!tasks.value.length) return false;
  
  try {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
    const address = await signer.getAddress();
    
    const admin = await contract.admin();
    const isAdmin = admin.toLowerCase() === address.toLowerCase();
    
    // Get project info to check completion status
    const projectInfo = await contract.getProjectInfo(props.projectId);
    if (projectInfo.isCompleted) {
      return false;  // Don't show verify button if project is already completed
    }
    
    return isAdmin && tasks.value.every(task => task.completed);
  } catch (error) {
    console.error('Error checking verify permission:', error);
    return false;
  }
});

const loadProjectInfo = async (contract) => {
  const info = await contract.getProjectInfo(props.projectId);
  projectInfo.value = {
    name: info.name,
    teamSize: info.teamSize.toNumber(),
    taskCount: info.taskCount.toNumber(),
    isCompleted: info.isCompleted
  };
};

const loadTasks = async () => {
  try {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this dApp');
      return;
    }

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
    const signer = provider.getSigner();
    const address = await signer.getAddress();

    // Load project info and team members
    const [projectInfo, teamMembers] = await Promise.all([
      contract.getProjectInfo(props.projectId),
      contract.getTeamMembers(props.projectId)
    ]);

    console.log('Current address:', address);
    console.log('Team members:', teamMembers);
    const isProjectMember = teamMembers.some(member => member.toLowerCase() === address.toLowerCase());
    console.log('Is project member:', isProjectMember);

    // Get task IDs for the project
    const taskIds = await contract.getTaskIds(props.projectId);
    
    // Load tasks
    const taskPromises = taskIds.map(async (taskId) => {
      const task = await contract.getTask(props.projectId, taskId);
      let status = 'PENDING';
      if (task.verified) {
        status = 'VERIFIED';
      } else if (task.completed) {
        status = 'COMPLETED';
      }
      
      const isAssignedToMe = task.assignedTo.toLowerCase() === address.toLowerCase();
      console.log('Task', taskId.toString(), {
        assignedTo: task.assignedTo,
        currentAddress: address,
        isAssignedTo: isAssignedToMe
      });
      
      return {
        id: taskId.toString(),
        projectId: props.projectId,
        description: task.description,
        assignedTo: task.assignedTo,
        deadline: task.deadline.toNumber(),
        reward: task.reward,
        status: status,
        completed: task.completed,
        verified: task.verified,
        isAssignedToMe
      };
    });

    tasks.value = await Promise.all(taskPromises);
  } catch (error) {
    console.error('Error loading tasks:', error);
    alert('Failed to load tasks. Please try again.');
  } finally {
    isLoading.value = false;
  }
};

const completeTask = async (task) => {
  try {
    isCompleting.value = true;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
    const address = await signer.getAddress();

    // Check if current user is assigned to this task
    if (task.assignedTo.toLowerCase() !== address.toLowerCase()) {
      alert('Only the assigned user can complete this task.');
      return;
    }

    const tx = await contract.completeTask(task.projectId, task.id);
    await tx.wait();
    await loadTasks();
  } catch (error) {
    console.error('Error completing task:', error);
    alert('Failed to complete task. Please try again.');
  } finally {
    isCompleting.value = false;
  }
};

const verifyProject = async () => {
  try {
    isVerifying.value = true;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

    // Get current account
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const currentAccount = accounts[0];

    // Check if current account is admin
    const admin = await contract.admin();
    if (admin.toLowerCase() !== currentAccount.toLowerCase()) {
      alert('Only admin can verify the project.');
      return;
    }

    // Calculate total reward
    const totalReward = tasks.value.reduce((sum, task) => {
      if (!task.verified) {  // Only include unverified tasks
        const reward = ethers.BigNumber.from(task.reward.toString());
        return sum.add(reward);
      }
      return sum;
    }, ethers.BigNumber.from(0));

    if (totalReward.isZero()) {
      alert('No rewards to distribute.');
      return;
    }

    console.log('Total reward to send:', ethers.utils.formatEther(totalReward), 'ETH');

    const tx = await contract.verifyProject(props.projectId, {
      value: totalReward
    });
    await tx.wait();
    await loadTasks();
  } catch (error) {
    console.error('Error verifying project:', error);
    if (error.code === -32603) {
      alert('Failed to verify project. Make sure you have enough ETH to pay rewards.');
    } else {
      alert('Failed to verify project. Please try again.');
    }
  } finally {
    isVerifying.value = false;
  }
};

watch(() => props.projectId, () => {
  loadTasks();
});

onMounted(loadTasks);
</script>

<style scoped>
.task-list-container {
  width: 100%;
}

.task-list {
  display: grid;
  gap: 1rem;
}

.task-item {
  background: #f8fafc;
  border-radius: 6px;
  padding: 1rem;
  border: 1px solid #e2e8f0;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.task-header h4 {
  margin: 0;
  color: var(--text-color);
  font-size: 1rem;
}

.task-id {
  font-size: 0.875rem;
  color: #64748b;
  font-family: monospace;
}

.task-details {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.task-info {
  flex: 1;
}

.task-info p {
  margin: 0.25rem 0;
  color: #64748b;
  font-size: 0.875rem;
}

.task-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

.status-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-badge.pending {
  background-color: #fef3c7;
  color: #92400e;
}

.status-badge.completed {
  background-color: #dcfce7;
  color: #166534;
}

.status-badge.verified {
  background-color: #dbeafe;
  color: #1e40af;
}

.loading {
  text-align: center;
  color: #64748b;
  padding: 2rem;
}

.verify-project {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8fafc;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  text-align: center;
}

button {
  min-width: 120px;
}
</style> 