/**
 * Storage configuration for Sovern
 * Defaults to /mnt/SOVERN (thumb drive), falls back to local ./data
 */

import path from 'path';
import os from 'os';
import fs from 'fs';

const getStoragePath = (): string => {
  // Try thumb drive first
  const thumbDrivePath = '/mnt/SOVERN';
  if (fs.existsSync(thumbDrivePath)) {
    return thumbDrivePath;
  }

  // Try alternate Linux mount point
  const altPath = '/media/SOVERN';
  if (fs.existsSync(altPath)) {
    return altPath;
  }

  // Windows mount point
  const windowsPath = 'X:\\SOVERN'; // Common thumb drive letter
  if (fs.existsSync(windowsPath)) {
    return windowsPath;
  }

  // Fallback to local storage
  const fallback = path.join(process.cwd(), 'data');
  console.warn(
    `Thumb drive not found at ${thumbDrivePath}, ${altPath}, or ${windowsPath}. Using local fallback: ${fallback}`
  );
  return fallback;
};

export const CONFIG = {
  // Storage
  STORAGE_PATH: getStoragePath(),
  DB_NAME: 'sovern.db',

  // Ollama
  OLLAMA_HOST: process.env.OLLAMA_HOST || 'http://localhost:11434',
  OLLAMA_MODEL: process.env.OLLAMA_MODEL || 'llama3.2:1b',
  OLLAMA_TIMEOUT: 30000, // 30 seconds

  // Server
  PORT: parseInt(process.env.PORT || '3001'),
  NODE_ENV: process.env.NODE_ENV || 'development',

  // Reasoning
  MAX_CONGRESS_DEPTH: 5,
  MIN_COMPLEXITY_WEIGHT: 1.0,
  MAX_COMPLEXITY_WEIGHT: 9.0,
};

// Ensure storage path exists
try {
  fs.mkdirSync(CONFIG.STORAGE_PATH, { recursive: true });
  console.log(`✓ Storage path ready: ${CONFIG.STORAGE_PATH}`);
} catch (err) {
  console.error(`Failed to create storage path: ${err}`);
  process.exit(1);
}

export const DB_PATH = path.join(CONFIG.STORAGE_PATH, CONFIG.DB_NAME);
