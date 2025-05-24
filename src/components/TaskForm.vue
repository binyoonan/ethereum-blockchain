<template>
  <div class="card">
    <h2>Create New Task</h2>
    <form @submit.prevent="createTask">
      <div class="form-group">
        <label for="projectId">Project ID</label>
        <input
          type="number"
          id="projectId"
          v-model="projectId"
          required
          min="0"
          placeholder="Enter project ID"
        />
      </div>
      <div class="form-group">
        <label for="taskId">Task ID</label>
        <input
          type="number"
          id="taskId"
          v-model="taskId"
          required
          min="0"
          placeholder="Enter task ID"
        />
      </div>
      <div class="form-group">
        <label for="description">Description</label>
        <textarea
          id="description"
          v-model="description"
          required
          placeholder="Enter task description"
          rows="3"
        ></textarea>
      </div>
      <div class="form-group">
        <label for="assignedTo">Assigned To (address)</label>
        <input
          type="text"
          id="assignedTo"
          v-model="assignedTo"
          required
          placeholder="0x..."
        />
      </div>
      <div class="form-group">
        <label for="deadline">Deadline (days from now)</label>
        <input
          type="number"
          id="deadline"
          v-model="deadline"
          required
          min="1"
          placeholder="Enter number of days"
        />
      </div>
      <div class="form-group">
        <label for="reward">Reward (ETH)</label>
        <input
          type="number"
          id="reward"
          v-model="reward"
          required
          min="0"
          step="0.001"
          placeholder="Enter reward amount"
        />
      </div>
      <button type="submit" class="btn btn-primary" :disabled="isLoading">
        {{ isLoading ? 'Creating...' : 'Create Task' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../contracts/config';

const projectId = ref('');
const taskId = ref('');
const description = ref('');
const assignedTo = ref('');
const deadline = ref('');
const reward = ref('');
const isLoading = ref(false);

const emit = defineEmits(['task-created']);

const createTask = async () => {
  try {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this dApp');
      return;
    }

    // Request account access
    await window.ethereum.request({ method: 'eth_requestAccounts' });

    isLoading.value = true;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

    // Check if current account is admin
    const admin = await contract.admin();
    const currentAccount = await signer.getAddress();
    if (admin.toLowerCase() !== currentAccount.toLowerCase()) {
      alert('Only admin can create tasks.');
      return;
    }

    // Check if project exists
    const projectInfo = await contract.getProjectInfo(parseInt(projectId.value));
    if (!projectInfo.name) {
      alert('Project does not exist. Please create the project first.');
      return;
    }

    const rewardInWei = ethers.utils.parseEther(reward.value.toString());
    
    // Calculate deadline timestamp: current time + (days * 24 * 60 * 60)
    const daysInSeconds = parseInt(deadline.value) * 24 * 60 * 60;
    const deadlineTimestamp = Math.floor(Date.now() / 1000) + daysInSeconds;

    console.log('Creating task with params:', {
      projectId: parseInt(projectId.value),
      taskId: parseInt(taskId.value),
      description: description.value,
      assignedTo: assignedTo.value,
      deadline: deadlineTimestamp,
      reward: rewardInWei.toString()
    });

    const tx = await contract.createTask(
      parseInt(projectId.value),
      parseInt(taskId.value),
      description.value,
      assignedTo.value,
      deadlineTimestamp,
      rewardInWei
    );
    await tx.wait();
    
    // Reset form
    projectId.value = '';
    taskId.value = '';
    description.value = '';
    assignedTo.value = '';
    deadline.value = '';
    reward.value = '';
    
    // Emit event to refresh task list
    emit('task-created');
  } catch (error) {
    console.error('Error creating task:', error);
    if (error.code === -32603) {
      const errorData = error.data;
      if (errorData && errorData.message) {
        if (errorData.message.includes('Project does not exist')) {
          alert('Project does not exist. Please create the project first.');
        } else if (errorData.message.includes('Task ID already exists')) {
          alert('Task ID already exists. Please use a different Task ID.');
        } else {
          alert('Failed to create task. Please check the console for details.');
        }
      } else {
        alert('Failed to create task. Make sure you are the admin and the project exists.');
      }
    } else if (error.code === 'UNSUPPORTED_OPERATION') {
      alert('Please connect to MetaMask and ensure you are on the correct network.');
    } else {
      alert('Failed to create task. Please try again.');
    }
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
.card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

h2 {
  margin-bottom: 1.5rem;
  color: var(--text-color);
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  color: var(--text-color);
  font-weight: 500;
}

input,
textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

textarea {
  resize: vertical;
  min-height: 100px;
}

input:focus,
textarea:focus {
  outline: none;
  border-color: var(--primary-color);
  box-shadow: 0 0 0 2px rgba(79, 70, 229, 0.1);
}

button {
  width: 100%;
  margin-top: 1rem;
}

button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}
</style> 