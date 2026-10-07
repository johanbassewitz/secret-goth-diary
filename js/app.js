'use strict';

const LS_PASSWORD = 'goth_diary_password';
const LS_NOTES = 'goth_diary_notes';

const $ = (id) => document.getElementById(id);

const lockScreen = $('lock-screen');
const app = $('app');
const passwordInput = $('password-input');
const lockSub = $('lock-sub');
const lockError = $('lock-error');
const unlockBtn = $('unlock-btn');
const togglePassword = $('toggle-password');

const emptyState = $('empty-state');
const paper = $('paper');
const noteTitle = $('note-title');
const noteDate = $('note-date');
const noteContent = $('note-content');
const paperWords = $('paper-words');
const saveIndicator = $('save-indicator');

const newNoteBtn = $('new-note-btn');
const searchInput = $('search-input');
const notesList = $('notes-list');
const lockBtn = $('lock-btn');

let notes = [];
let currentNoteId = null;
let saveTimer = null;
let confirmDeleteId = null;
let confirmTimer = null;

/* ---------- password hashing (simple local hash) ---------- */
function hashPassword(str) {
  let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
  for (let i = 0; i < str.length; i++) {
    const ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  return (h2 >>> 0).toString(16) + (h1 >>> 0).toString(16);
}

/* ---------- storage ---------- */
function loadNotes() {
  try {
    const raw = localStorage.getItem(LS_NOTES);
    notes = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(notes)) notes = [];
  } catch {
    notes = [];
  }
}

function persistNotes() {
  localStorage.setItem(LS_NOTES, JSON.stringify(notes));
}

/* ---------- lock / unlock ---------- */
function initLockScreen() {
  const stored = localStorage.getItem(LS_PASSWORD);
  if (stored) {
    lockSub.innerHTML = 'Enter your password to reopen your diary.';
    passwordInput.placeholder = 'Enter your password';
  } else {
    lockSub.innerHTML = 'Set a password the first time you open the app.<br>You\'ll need to enter it every time you reopen your diary.';
    passwordInput.placeholder = 'Create a password (min. 4 characters)';
  }
  passwordInput.value = '';
  lockError.textContent = '';
  setTimeout(() => passwordInput.focus(), 100);
}

function handleUnlock() {
  const value = passwordInput.value;
  const stored = localStorage.getItem(LS_PASSWORD);

  if (!stored) {
    if (value.length < 4) {
      showLockError('Password must be at least 4 characters.');
      shakeLock();
      return;
    }
    localStorage.setItem(LS_PASSWORD, hashPassword(value));
    enterApp();
  } else {
    if (hashPassword(value) === stored) {
      enterApp();
    } else {
      showLockError('Incorrect password. Try again.');
      shakeLock();
      passwordInput.select();
    }
  }
}

function showLockError(msg) {
  lockError.textContent = msg;
}

function shakeLock() {
  const card = document.querySelector('.lock-card');
  card.classList.remove('shake');
  void card.offsetWidth;
  card.classList.add('shake');
}

function enterApp() {
  lockScreen.classList.add('hidden');
  app.classList.remove('hidden');
  loadNotes();
  renderNotes();
  if (notes.length > 0) {
    selectNote(notes[0].id);
  }
}

function lockApp() {
  currentNoteId = null;
  app.classList.add('hidden');
  lockScreen.classList.remove('hidden');
  initLockScreen();
}

/* ---------- notes ---------- */
function createNote() {
  const now = new Date();
  const note = {
    id: 'n_' + now.getTime().toString(36) + Math.random().toString(36).slice(2, 7),
    title: '',
    content: '',
    createdAt: now.toISOString(),
    updatedAt: now.toISOString()
  };
  notes.unshift(note);
  persistNotes();
  renderNotes();
  selectNote(note.id);
  noteTitle.focus();
}

function selectNote(id) {
  currentNoteId = id;
  const note = notes.find(n => n.id === id);
  if (!note) return;
  emptyState.classList.add('hidden');
  paper.classList.remove('hidden');
  noteTitle.value = note.title;
  noteContent.value = note.content;
  noteDate.textContent = formatDate(note.createdAt);
  updateWordCount();
  renderNotes();
}

function deleteNote(id) {
  notes = notes.filter(n => n.id !== id);
  persistNotes();
  if (currentNoteId === id) {
    currentNoteId = null;
    paper.classList.add('hidden');
    emptyState.classList.remove('hidden');
    if (notes.length > 0) selectNote(notes[0].id);
  }
  renderNotes();
}

function saveCurrentNote() {
  const note = notes.find(n => n.id === currentNoteId);
  if (!note) return;
  note.title = noteTitle.value.trim();
  note.content = noteContent.value;
  note.updatedAt = new Date().toISOString();
  persistNotes();
  updateWordCount();
  renderNotes();
  flashSaved();
}

function flashSaved() {
  saveIndicator.textContent = 'All changes saved';
  saveIndicator.classList.add('visible');
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => saveIndicator.classList.remove('visible'), 1800);
}

function updateWordCount() {
  const text = noteContent.value.trim();
  const words = text ? text.split(/\s+/).length : 0;
  paperWords.textContent = words + (words === 1 ? ' word' : ' words');
}

/* ---------- rendering ---------- */
function formatDate(iso) {
  const d = new Date(iso);
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  let h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, '0');
  const ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12 || 12;
  return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()} · ${h}:${m} ${ampm}`;
}

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function renderNotes() {
  const query = searchInput.value.trim().toLowerCase();
  const filtered = query
    ? notes.filter(n =>
        n.title.toLowerCase().includes(query) ||
        n.content.toLowerCase().includes(query))
    : notes;

  if (filtered.length === 0) {
    notesList.innerHTML = query
      ? '<div class="notes-empty">No notes match your search.</div>'
      : '<div class="notes-empty">No notes yet.<br>Begin your first entry.</div>';
    return;
  }

  notesList.innerHTML = filtered.map((note, i) => {
    const title = escapeHtml(note.title || 'Untitled');
    const preview = escapeHtml(note.content.slice(0, 120)) || '<em style="opacity:.6">Empty page...</em>';
    const active = note.id === currentNoteId ? ' active' : '';
    return `
      <div class="note-card${active}" data-id="${note.id}" style="animation-delay:${Math.min(i * 35, 350)}ms">
        <div class="note-card-top">
          <svg class="note-card-icon"><use href="#art-minibook"/></svg>
          <div style="flex:1;min-width:0">
            <div class="note-card-title">${title}</div>
            <div class="note-card-date">${formatDate(note.updatedAt)}</div>
          </div>
        </div>
        <div class="note-card-preview">${preview}</div>
        <button class="note-delete" data-delete="${note.id}" title="Delete note">
          <svg viewBox="0 0 24 24"><path d="M9 3 L10 3 L10 2 L14 2 L14 3 L15 3 L15 5 L9 5 Z M6 7 L18 7 L17 22 L7 22 Z M10 9 L10 20 M14 9 L14 20" stroke="currentColor" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>
        </button>
      </div>`;
  }).join('');
}

/* ---------- events ---------- */
unlockBtn.addEventListener('click', handleUnlock);
passwordInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') handleUnlock();
});

togglePassword.addEventListener('click', () => {
  const show = passwordInput.type === 'password';
  passwordInput.type = show ? 'text' : 'password';
  togglePassword.style.color = show ? '#c9a227' : '';
  togglePassword.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
});

lockBtn.addEventListener('click', lockApp);

newNoteBtn.addEventListener('click', createNote);

noteTitle.addEventListener('input', () => {
  saveIndicator.textContent = 'Saving...';
  saveIndicator.classList.add('visible', 'saving');
  clearTimeout(saveTimer);
  saveTimer = setTimeout(saveCurrentNote, 500);
});

noteContent.addEventListener('input', () => {
  saveIndicator.textContent = 'Saving...';
  saveIndicator.classList.add('visible', 'saving');
  clearTimeout(saveTimer);
  saveTimer = setTimeout(saveCurrentNote, 500);
});

searchInput.addEventListener('input', renderNotes);

notesList.addEventListener('click', (e) => {
  const deleteBtn = e.target.closest('[data-delete]');
  if (deleteBtn) {
    e.stopPropagation();
    const id = deleteBtn.getAttribute('data-delete');
    if (confirmDeleteId === id) {
      clearTimeout(confirmTimer);
      confirmDeleteId = null;
      deleteNote(id);
    } else {
      confirmDeleteId = id;
      renderNotes();
      const btn = notesList.querySelector(`[data-delete="${id}"]`);
      if (btn) btn.classList.add('confirm'), btn.textContent = 'Sure?';
      clearTimeout(confirmTimer);
      confirmTimer = setTimeout(() => {
        confirmDeleteId = null;
        renderNotes();
      }, 3000);
    }
    return;
  }
  const card = e.target.closest('.note-card');
  if (card) selectNote(card.getAttribute('data-id'));
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) lockApp();
});

if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}

initLockScreen();
