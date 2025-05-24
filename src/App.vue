<template>
  <div id="app">
    <Navbar />
    <div class="container">
      <div class="left-panel">
        <ProjectForm @project-created="loadProjects" />
        <TaskForm @task-created="loadTasks" />
      </div>
      <div class="right-panel">
        <ProjectList ref="projectList" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import Navbar from './components/Navbar.vue';
import ProjectForm from './components/ProjectForm.vue';
import TaskForm from './components/TaskForm.vue';
import ProjectList from './components/ProjectList.vue';

const projectList = ref(null);

const loadProjects = () => {
  if (projectList.value) {
    projectList.value.loadProjects();
  }
};

const loadTasks = () => {
  if (projectList.value) {
    projectList.value.loadProjects();
  }
};
</script>

<style>
:root {
  --primary-color: #4f46e5;
  --primary-hover: #4338ca;
  --secondary-color: #64748b;
  --secondary-hover: #475569;
  --background-color: #f1f5f9;
  --text-color: #1e293b;
  --border-color: #e2e8f0;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  line-height: 1.5;
  color: var(--text-color);
  background-color: var(--background-color);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 2rem;
}

.left-panel {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.right-panel {
  min-width: 0;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background-color: var(--primary-color);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: var(--primary-hover);
}

.btn-secondary {
  background-color: var(--secondary-color);
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background-color: var(--secondary-hover);
}

.btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .container {
    padding: 1rem;
  }
  
  .grid {
    grid-template-columns: 1fr;
  }
}
</style>
