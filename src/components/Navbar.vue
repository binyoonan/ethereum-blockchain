<template>
  <nav class="navbar">
    <div class="navbar-brand">
      <h1>Project Management DApp</h1>
    </div>
    <div class="navbar-menu">
      <button v-if="!isConnected" class="btn btn-primary" @click="connectWallet">
        Connect Wallet
      </button>
      <div v-else class="wallet-info">
        <span class="address">{{ shortAddress(address) }}</span>
        <span v-if="isAdmin" class="admin-badge">Admin</span>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../contracts/config';

const isConnected = ref(false);
const address = ref('');
const isAdmin = ref(false);

const shortAddress = (addr) => {
  if (!addr) return '';
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
};

const connectWallet = async () => {
  try {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this dApp');
      return;
    }

    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    address.value = accounts[0];
    isConnected.value = true;

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
    const adminAddress = await contract.admin();
    isAdmin.value = adminAddress.toLowerCase() === address.value.toLowerCase();

    // Listen for account changes
    window.ethereum.on('accountsChanged', (accounts) => {
      address.value = accounts[0];
      isAdmin.value = adminAddress.toLowerCase() === accounts[0].toLowerCase();
    });
  } catch (error) {
    console.error('Error connecting wallet:', error);
    alert('Failed to connect wallet. Please try again.');
  }
};

onMounted(async () => {
  if (typeof window.ethereum !== 'undefined') {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const accounts = await provider.listAccounts();
    if (accounts.length > 0) {
      address.value = accounts[0];
      isConnected.value = true;

      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
      const adminAddress = await contract.admin();
      isAdmin.value = adminAddress.toLowerCase() === address.value.toLowerCase();
    }
  }
});
</script>

<style scoped>
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0;
  margin-bottom: 2rem;
}

.navbar-brand h1 {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--text-color);
}

.wallet-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.address {
  font-family: monospace;
  font-size: 0.875rem;
  color: var(--text-color);
}

.admin-badge {
  background-color: var(--primary-color);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 500;
}
</style> 