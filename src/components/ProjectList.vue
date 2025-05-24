<template>
  <div class="card">
    <h2>Projects</h2>
    <div v-if="isLoading" class="loading">Loading projects...</div>
    <div v-else-if="projects.length === 0" class="empty-state">
      No projects found. Create a new project to get started.
    </div>
    <div v-else class="project-list">
      <div v-for="project in projects" :key="project.id" class="project-item" @click="openTaskModal(project)">
        <div class="project-info">
          <h3>{{ project.name }}</h3>
          <span class="project-id">ID: {{ project.id }}</span>
        </div>
        <div class="project-members">
          <p><strong>Team Members:</strong> {{ project.members.length }}</p>
          <p><strong>Tasks:</strong> {{ project.taskCount }}</p>
          <span :class="['status-badge', project.isCompleted ? 'completed' : 'pending']">
            {{ project.isCompleted ? 'Completed' : 'In Progress' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Task Modal -->
    <div v-if="showTaskModal" class="modal-overlay" @click="closeTaskModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>{{ selectedProject?.name }} - Tasks</h2>
          <button class="close-button" @click="closeTaskModal">&times;</button>
        </div>
        <div class="modal-body">
          <TaskList :project-id="selectedProject?.id" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../contracts/config';
import TaskList from './TaskList.vue';

const projects = ref([]);
const isLoading = ref(true);
const showTaskModal = ref(false);
const selectedProject = ref(null);

const shortAddress = (addr) => {
  if (!addr) return '';
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
};

const loadProjects = async () => {
  try {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this dApp');
      return;
    }

    isLoading.value = true;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
    const projectIds = await contract.getProjectIds();
    
    const projectPromises = projectIds.map(async (id) => {
      const info = await contract.getProjectInfo(id);
      const members = await contract.getTeamMembers(id);
      return {
        id: id.toString(),
        name: info.name,
        members: members,
        taskCount: info.taskCount.toNumber(),
        isCompleted: info.isCompleted
      };
    });

    projects.value = await Promise.all(projectPromises);
  } catch (error) {
    console.error('Error loading projects:', error);
    alert('Failed to load projects. Please try again.');
  } finally {
    isLoading.value = false;
  }
};

const openTaskModal = (project) => {
  selectedProject.value = project;
  showTaskModal.value = true;
};

const closeTaskModal = () => {
  showTaskModal.value = false;
  selectedProject.value = null;
};

// Expose loadProjects function to parent component
defineExpose({
  loadProjects
});

onMounted(loadProjects);
</script>

<style scoped>
.project-list {
  display: grid;
  gap: 1rem;
}

.project-item {
  background: #f8fafc;
  border-radius: 6px;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.2s ease;
}

.project-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.project-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.project-info h3 {
  margin: 0;
  color: var(--text-color);
  font-size: 1.125rem;
}

.project-id {
  font-size: 0.875rem;
  color: #64748b;
  font-family: monospace;
}

.project-members {
  color: #64748b;
  font-size: 0.875rem;
  display: flex;
  gap: 1rem;
  align-items: center;
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

.loading {
  text-align: center;
  color: #64748b;
  padding: 2rem;
}

.empty-state {
  text-align: center;
  color: #64748b;
  padding: 2rem;
  background: #f8fafc;
  border-radius: 6px;
  border: 1px dashed #e2e8f0;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow-y: auto;
  position: relative;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid var(--border-color);
  position: sticky;
  top: 0;
  background: white;
  z-index: 1;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.25rem;
  color: var(--text-color);
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #64748b;
  cursor: pointer;
  padding: 0.5rem;
  line-height: 1;
}

.close-button:hover {
  color: var(--text-color);
}

.modal-body {
  padding: 1.5rem;
}
</style> 