<template>
  <!-- 頂部控制列 -->
  <div class="w-full max-w-3xl flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 mb-6 sm:mb-8 bg-white p-4 rounded-2xl shadow-sm border border-slate-100">
    <h1 class="w-full sm:w-auto text-xl sm:text-2xl font-bold text-slate-800 tracking-wide truncate">字卡學習</h1>
    <div class="w-full sm:w-auto flex items-center justify-end gap-3">
      <button 
        @click="showInfo = true"
        class="p-2.5 rounded-xl bg-slate-50 text-slate-500 hover:bg-slate-100 hover:text-indigo-600 transition-colors border border-slate-200"
        title="快捷鍵與說明"
      >
        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
      </button>
      <label class="cursor-pointer bg-indigo-600 hover:bg-indigo-700 text-white px-4 sm:px-5 py-2.5 rounded-xl flex items-center justify-center gap-2 shadow-sm transition-all duration-200 active:scale-95 min-w-0">
        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
        </svg>
        <span class="font-medium whitespace-nowrap">匯入 CSV</span>
        <input type="file" accept=".csv" class="hidden" @change="handleFileUpload" />
      </label>
    </div>
  </div>

  <template v-if="allCards.length > 0">
    <template v-if="queue.length > 0">
      <div class="w-full max-w-3xl flex flex-col items-center">
        <!-- 進度條與統計 -->
        <div class="w-full mb-6 grid grid-cols-[auto,1fr] sm:grid-cols-[auto,1fr,auto] items-center gap-3 text-sm">
          <span class="font-bold text-slate-600 bg-white px-3 py-1.5 rounded-lg shadow-sm border border-slate-100 whitespace-nowrap">
            {{ queue.length }} / {{ allCards.length }}
          </span>
          
          <div class="flex-1 min-w-[120px] bg-slate-200 rounded-full h-2.5 overflow-hidden shadow-inner">
            <div 
              class="bg-indigo-500 h-full rounded-full transition-all duration-500 ease-out" 
              :style="{ width: `${((allCards.length - queue.length) / allCards.length) * 100}%` }"
            ></div>
          </div>

          <div class="col-span-2 sm:col-span-1 flex flex-wrap justify-center gap-x-3 gap-y-1 sm:gap-4 bg-white px-3 py-1.5 rounded-lg shadow-sm border border-slate-100 text-xs sm:text-sm">
            <span class="text-red-500 font-bold">Again: {{ stats.again }}</span>
            <span class="text-orange-500 font-bold">Hard: {{ stats.hard }}</span>
            <span class="text-blue-500 font-bold">Good: {{ stats.good }}</span>
            <span class="text-green-500 font-bold">Easy: {{ stats.easy }}</span>
          </div>
        </div>

        <!-- 卡片本體 -->
        <div 
          @click="isFlipped = !isFlipped"
          class="w-full min-h-[min(520px,calc(100vh-220px))] bg-white rounded-3xl shadow-xl hover:shadow-2xl transition-all duration-300 cursor-pointer p-5 md:p-8 flex flex-col justify-center border border-slate-100 relative group overflow-hidden"
        >
          <div class="absolute top-6 right-6 text-slate-300 group-hover:text-indigo-300 transition-colors">
            <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/>
            </svg>
          </div>

          <template v-if="!isFlipped">
            <!-- 卡片正面 -->
            <div class="text-center flex flex-col sm:flex-row items-center justify-center gap-5 sm:gap-6 my-auto min-w-0">
              <h2 class="max-w-full text-4xl sm:text-6xl md:text-7xl font-extrabold text-slate-800 tracking-tight break-words leading-tight">
                {{ queue[0].word }}
              </h2>
              <button 
                @click="handleSpeakerClick($event, queue[0].word)" 
                class="p-4 rounded-full bg-indigo-50 text-indigo-600 hover:bg-indigo-100 transition-colors shadow-sm active:scale-90 flex-shrink-0"
                title="朗讀單字 (Enter)"
              >
                <svg class="w-9 h-9" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>
                </svg>
              </button>
            </div>
          </template>
          <template v-else>
            <!-- 卡片背面 -->
            <div class="h-full flex flex-col">
              <div class="w-full h-32 sm:h-44 rounded-xl overflow-hidden mb-3 shrink-0 bg-slate-100 shadow-sm border border-slate-100">
                <img 
                  :src="`https://loremflickr.com/400/240/${encodeURIComponent(queue[0].word)}`" 
                  :alt="queue[0].word" 
                  class="w-full h-full object-cover" 
                />
              </div>

              <div class="flex-1 min-h-0 overflow-y-auto text-left flex flex-col gap-1.5 text-slate-700 text-base pb-3 pr-1">
                <div 
                  v-for="(line, idx) in queue[0].parsed.lines" 
                  :key="idx" 
                  :class="['leading-tight', line.type === 'example' ? 'flex items-start gap-2 mt-1.5 pt-1.5 border-t border-slate-100' : '']"
                >
                  <span :class="[(line.type === 'basic' ? 'font-bold text-xl text-slate-800 mb-1 block' : ''), (line.type === 'tag' ? 'text-indigo-900 font-medium' : '')]">
                    {{ line.text }}
                  </span>
                  
                  <button 
                    v-if="line.type === 'example'"
                    @click="handleSpeakerClick($event, line.enText)" 
                    class="p-1.5 rounded-full bg-indigo-50 text-indigo-600 hover:bg-indigo-100 transition-colors shadow-sm active:scale-90 flex-shrink-0"
                    title="朗讀例句 (Enter)"
                  >
                    <svg class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>
                    </svg>
                  </button>
                </div>
              </div>

              <!-- SRS 控制按鈕 -->
              <div class="mt-auto pt-4 border-t border-slate-100 grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3 shrink-0">
                <button 
                  @click="handleReviewClick($event, 'again')" 
                  class="min-h-12 py-2.5 px-2 sm:px-4 rounded-xl bg-red-50 text-red-600 hover:bg-red-100 hover:shadow-sm font-bold transition-all active:scale-95 flex items-center justify-center text-center"
                >
                  <span class="text-sm sm:text-base leading-tight">Again [▲]</span>
                </button>
                <button 
                  @click="handleReviewClick($event, 'hard')" 
                  class="min-h-12 py-2.5 px-2 sm:px-4 rounded-xl bg-orange-50 text-orange-600 hover:bg-orange-100 hover:shadow-sm font-bold transition-all active:scale-95 flex items-center justify-center text-center"
                >
                  <span class="text-sm sm:text-base leading-tight">Hard [◄]</span>
                </button>
                <button 
                  @click="handleReviewClick($event, 'good')" 
                  class="min-h-12 py-2.5 px-2 sm:px-4 rounded-xl bg-blue-50 text-blue-600 hover:bg-blue-100 hover:shadow-sm font-bold transition-all active:scale-95 flex items-center justify-center text-center"
                >
                  <span class="text-sm sm:text-base leading-tight">Good [►]</span>
                </button>
                <button 
                  @click="handleReviewClick($event, 'easy')" 
                  class="min-h-12 py-2.5 px-2 sm:px-4 rounded-xl bg-green-50 text-green-600 hover:bg-green-100 hover:shadow-sm font-bold transition-all active:scale-95 flex items-center justify-center text-center"
                >
                  <span class="text-sm sm:text-base leading-tight">Easy [▼]</span>
                </button>
              </div>
            </div>
          </template>
        </div>
      </div>
    </template>
    <template v-else>
      <!-- 完成練習畫面 -->
      <div class="flex-1 w-full max-w-3xl flex flex-col items-center justify-center text-slate-600 gap-6 mt-12 bg-white p-10 sm:p-16 rounded-3xl shadow-xl border border-slate-100 relative overflow-hidden">
        <div class="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-green-400 to-indigo-500"></div>
        <div class="w-24 h-24 bg-green-50 rounded-full flex items-center justify-center mb-2">
          <svg class="w-14 h-14 text-green-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
        </div>
        <h2 class="text-3xl sm:text-4xl font-extrabold text-slate-800 tracking-tight">完成練習！</h2>
        <p class="text-lg text-slate-500 font-medium">太棒了！你已經複習完所有的單字卡了。</p>
        
        <div class="flex flex-wrap justify-center gap-4 sm:gap-8 mt-6 bg-slate-50 p-6 rounded-2xl border border-slate-100 w-full max-w-lg">
          <div class="text-center flex-1 min-w-[70px]">
            <div class="text-4xl font-bold text-red-500">{{ stats.again }}</div>
            <div class="text-sm font-bold text-slate-400 mt-2 uppercase tracking-wider">Again</div>
          </div>
          <div class="text-center flex-1 min-w-[70px]">
            <div class="text-4xl font-bold text-orange-500">{{ stats.hard }}</div>
            <div class="text-sm font-bold text-slate-400 mt-2 uppercase tracking-wider">Hard</div>
          </div>
          <div class="text-center flex-1 min-w-[70px]">
            <div class="text-4xl font-bold text-blue-500">{{ stats.good }}</div>
            <div class="text-sm font-bold text-slate-400 mt-2 uppercase tracking-wider">Good</div>
          </div>
          <div class="text-center flex-1 min-w-[70px]">
            <div class="text-4xl font-bold text-green-500">{{ stats.easy }}</div>
            <div class="text-sm font-bold text-slate-400 mt-2 uppercase tracking-wider">Easy</div>
          </div>
        </div>

        <button 
          @click="restartPractice"
          class="mt-8 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-4 rounded-xl font-bold text-lg shadow-md hover:shadow-lg transition-all active:scale-95 w-full sm:w-auto min-w-[200px]"
        >
          <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
          </svg>
          重新開始
        </button>
      </div>
    </template>
  </template>
  <template v-else>
    <!-- 初始空狀態 -->
    <div class="flex-1 w-full max-w-3xl flex flex-col items-center justify-center text-slate-400 gap-6 mt-20">
      <div class="w-32 h-32 bg-slate-100 rounded-full flex items-center justify-center shadow-inner">
        <svg class="w-16 h-16 text-slate-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>
        </svg>
      </div>
      <p class="text-xl font-medium text-slate-500">請點擊上方按鈕匯入 CSV 檔案開始學習</p>
      <div class="text-sm text-slate-400 text-center max-w-md">
        支援格式：第一欄為單字，第二欄為內容資訊。單字會顯示在正面，其餘資訊將於背面分行顯示。
      </div>
    </div>
  </template>

  <!-- 快捷鍵說明視窗 -->
  <div 
    v-if="showInfo"
    class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center z-50 p-4" 
    @click="showInfo = false"
  >
    <div 
      class="bg-white rounded-3xl shadow-2xl w-full max-w-md p-6 relative modal-enter" 
      @click.stop
    >
      <button 
        class="absolute top-5 right-5 text-slate-400 hover:text-slate-700 transition-colors bg-slate-100 rounded-full p-1" 
        @click="showInfo = false"
      >
        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
      <h3 class="text-xl font-bold text-slate-800 mb-5 flex items-center gap-2">
        <svg class="w-6 h-6 text-indigo-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
        快捷鍵與操作說明
      </h3>
      
      <div class="space-y-3 text-slate-700">
        <div class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100">
          <span class="font-medium">朗讀發音</span>
          <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">Enter</kbd>
        </div>
        <div class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100">
          <span class="font-medium">翻轉卡片</span>
          <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">Space</kbd>
        </div>
        
        <div class="p-4 bg-slate-50 rounded-xl border border-slate-100 space-y-3">
          <div class="font-bold text-slate-800 mb-2 pb-2 border-b border-slate-200 flex items-center gap-2">
            卡片分類評估 <span class="text-xs font-normal text-slate-500">(限卡片背面)</span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-red-500 font-bold">Again <span class="text-sm font-medium opacity-80">(立刻複習)</span></span>
            <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">▲ Up</kbd>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-orange-500 font-bold">Hard <span class="text-sm font-medium opacity-80">(稍後複習)</span></span>
            <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">◄ Left</kbd>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-blue-500 font-bold">Good <span class="text-sm font-medium opacity-80">(最後複習)</span></span>
            <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">► Right</kbd>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-green-500 font-bold">Easy <span class="text-sm font-medium opacity-80">(不再出現)</span></span>
            <kbd class="px-2.5 py-1 bg-white border border-slate-200 rounded text-sm shadow-sm font-mono text-slate-600">▼ Down</kbd>
          </div>
        </div>
      </div>
      
      <button 
        @click="showInfo = false"
        class="mt-6 w-full py-3 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded-xl font-bold transition-colors"
      >
        我知道了
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted, onUnmounted } from 'vue';

const allCards = ref([]);
const queue = ref([]);
const isFlipped = ref(false);
const stats = reactive({ again: 0, hard: 0, good: 0, easy: 0 });
const showInfo = ref(false);

const speakText = (text) => {
  if (!text || !window.speechSynthesis) return;
  window.speechSynthesis.cancel();
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'en-US';
  window.speechSynthesis.speak(utterance);
};

const parseDetails = (detailsStr) => {
  const parts = detailsStr.split('【');
  const lines = [];
  let exampleEnglish = '';

  if (parts[0].trim()) {
    lines.push({ type: 'basic', text: parts[0].trim() });
  }

  for (let i = 1; i < parts.length; i++) {
    const text = '【' + parts[i].trim();
    
    if (text.startsWith('【例句】')) {
      const sentenceContent = text.replace('【例句】', '').trim();
      const match = sentenceContent.match(/^([^(（]+)/); 
      exampleEnglish = match ? match[1].trim() : sentenceContent;
      lines.push({ type: 'example', text: text, enText: exampleEnglish });
    } else {
      lines.push({ type: 'tag', text: text });
    }
  }
  
  return { lines, exampleEnglish };
};

const handleFileUpload = (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
    const text = event.target.result;
    const lines = text.split('\n').filter(line => line.trim() !== '');
    
    const parsedCards = lines.map(line => {
      const firstCommaIndex = line.indexOf(',');
      if (firstCommaIndex === -1) return null;
      
      const word = line.substring(0, firstCommaIndex).trim();
      const details = line.substring(firstCommaIndex + 1).trim();
      
      return { 
        word, 
        parsed: parseDetails(details) 
      };
    }).filter(Boolean);

    if (parsedCards.length > 0) {
      allCards.value = parsedCards;
      queue.value = parsedCards;
      isFlipped.value = false;
      Object.assign(stats, { again: 0, hard: 0, good: 0, easy: 0 });
    }
  };
  reader.readAsText(file);
};

watch([queue, isFlipped], () => {
  if (queue.value.length === 0) return;
  const currentCard = queue.value[0];
  
  if (!isFlipped.value) {
    speakText(currentCard.word);
  } else {
    if (currentCard.parsed.exampleEnglish) {
      speakText(currentCard.parsed.exampleEnglish);
    }
  }
}, { flush: 'post' });

const performReview = (rating) => {
  if (queue.value.length === 0) return;
  stats[rating]++;
  
  const current = queue.value[0];
  const rest = queue.value.slice(1);
  const newQueue = [...rest];
  
  if (rating === 'again') {
    newQueue.splice(Math.min(1, rest.length), 0, current); 
  } else if (rating === 'hard') {
    newQueue.splice(Math.ceil(rest.length / 2), 0, current); 
  } else if (rating === 'good') {
    newQueue.push(current); 
  }
  
  queue.value = newQueue;
  isFlipped.value = false;
};

const handleKeyDown = (e) => {
  if (showInfo.value) {
    if (e.key === 'Escape') showInfo.value = false;
    return;
  }

  if (e.key === 'Enter') {
    e.preventDefault();
    if (queue.value.length === 0) return;
    
    const currentCard = queue.value[0];
    if (!isFlipped.value) {
      speakText(currentCard.word);
    } else {
      if (currentCard.parsed.exampleEnglish) {
        speakText(currentCard.parsed.exampleEnglish);
      }
    }
  } else if (e.code === 'Space') {
    e.preventDefault(); 
    if (queue.value.length > 0) {
      isFlipped.value = !isFlipped.value;
    }
  } else if (isFlipped.value && queue.value.length > 0) {
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      performReview('again');
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      performReview('hard');
    } else if (e.key === 'ArrowRight') {
      e.preventDefault();
      performReview('good');
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      performReview('easy');
    }
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});

watch(queue, () => {
  if (queue.value.length === 0) return;
  const nextCards = queue.value.slice(1, 4); 
  nextCards.forEach(card => {
    const img = new Image();
    img.src = `https://loremflickr.com/400/240/${encodeURIComponent(card.word)}`;
  });
});

const handleSpeakerClick = (e, text) => {
  e.stopPropagation();
  speakText(text);
};

const handleReviewClick = (e, rating) => {
  e.stopPropagation(); 
  performReview(rating);
};

const restartPractice = () => {
  queue.value = [...allCards.value];
  Object.assign(stats, { again: 0, hard: 0, good: 0, easy: 0 });
  isFlipped.value = false;
};
</script>
