<template>
  <div class="card">
    <h2>Create New Project</h2>
    <form @submit.prevent="createProject">
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
        <label for="name">Project Name</label>
        <input
          type="text"
          id="name"
          v-model="name"
          required
          placeholder="Enter project name"
        />
      </div>
      <div class="form-group">
        <label for="members">Team Members (comma-separated addresses)</label>
        <input
          type="text"
          id="members"
          v-model="members"
          required
          placeholder="0x123...,0x456..."
        />
      </div>
      <button type="submit" class="btn btn-primary" :disabled="isLoading">
        {{ isLoading ? 'Creating...' : 'Create Project' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../contracts/config';

const projectId = ref('');
const name = ref('');
const members = ref('');
const isLoading = ref(false);

const emit = defineEmits(['project-created']);

const createProject = async () => {
  try {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this dApp');
      return;
    }

    isLoading.value = true;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

    const memberAddresses = members.value.split(',').map(addr => addr.trim());
    
    const tx = await contract.createProject(
      projectId.value,
      name.value,
      memberAddresses
    );
    
    await tx.wait();
    
    // Reset form
    projectId.value = '';
    name.value = '';
    members.value = '';
    
    // Emit event to refresh project list
    emit('project-created');
  } catch (error) {
    console.error('Error creating project:', error);
    if (error.data?.message?.includes('Project ID already exists')) {
      alert('This Project ID already exists. Please choose a different ID.');
    } else {
      alert('Failed to create project. Please try again.');
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

input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

input:focus {
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