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
const isAdmin = ref(false);

const shortAddress = (addr) => {
  if (!addr) return '';
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
};

const formatDate = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString();
};

const formatEther = (wei) => {
  try {
    return ethers.utils.formatEther(wei || 0);
  } catch (e) {
    console.error("Error formatting ether value:", wei, e);
    return 'N/A';
  }
};

const canVerifyProject = computed(() => {
  const result = isAdmin.value 
         && tasks.value.every(task => task.completed) 
         && (projectInfo.value ? !projectInfo.value.isCompleted : false);
         
  console.log('canVerifyProject Computed:', {
    isAdmin: isAdmin.value,
    allTasksCompleted: tasks.value.every(task => task.completed),
    projectNotCompleted: projectInfo.value ? !projectInfo.value.isCompleted : 'Project Info not loaded',
    finalResult: result
  });

  return result;
});

const loadProjectInfo = async (contract) => {
  try {
    const info = await contract.getProjectInfo(props.projectId);
    projectInfo.value = {
      name: info.name,
      teamSize: info.teamSize.toNumber(),
      taskCount: info.taskCount.toNumber(),
      isCompleted: info.isCompleted
    };
  } catch (error) {
     console.error('Error loading project info:', error);
     projectInfo.value = null;
  }
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

    const adminAddress = await contract.admin();
    isAdmin.value = adminAddress.toLowerCase() === address.toLowerCase();
    console.log('Admin address:', adminAddress, 'Current address:', address, 'Is Admin:', isAdmin.value);

    const teamMembers = await contract.getTeamMembers(props.projectId);

    console.log('Current address:', address);
    console.log('Team members:', teamMembers);
    const isProjectMember = teamMembers.some(member => member.toLowerCase() === address.toLowerCase());
    console.log('Is project member:', isProjectMember);

    const taskIds = await contract.getTaskIds(props.projectId);
    
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
        isAssignedToMe,
        taskStatus: {
          completed: task.completed,
          verified: task.verified
        }
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
    
    await loadProjectInfo(contract);

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

    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const currentAccount = accounts[0];

    const admin = await contract.admin();
    if (admin.toLowerCase() !== currentAccount.toLowerCase()) {
      alert('Only admin can verify the project.');
      return;
    }

    const totalReward = tasks.value.reduce((sum, task) => {
      if (!task.verified) {
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
       let errorMessage = 'Failed to verify project.';
       if (error.data && error.data.message) {
           errorMessage += ' Error: ' + error.data.message;
       } else if (error.message) {
           errorMessage += ' Error: ' + error.message;
       }
        alert(errorMessage + ' Make sure you have enough ETH and are the admin.');
    } else if (error.message.includes('Only admin can call this function')){
        alert('Only admin can verify the project.');
    }
     else {
      alert('Failed to verify project. Please try again.');
    }
  } finally {
    isVerifying.value = false;
  }
};

watch(() => props.projectId, (newProjectId, oldProjectId) => {
  if (newProjectId && newProjectId !== oldProjectId) {
      loadTasks();
  }
}, { immediate: true });

onMounted(loadTasks);

defineExpose({
    loadTasks
});
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