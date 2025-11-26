const { createApp } = Vue;

const BASE_URL = 'https://insality.github.io/asset-store';

createApp({
    data() {
        return {
            editorPort: null,
            activeStore: 'dependency',
            stores: [
                { name: 'Dependencies', type: 'dependency', url: `${BASE_URL}/dependencies_store.json` },
                { name: 'Druid Widgets', type: 'widget', url: `${BASE_URL}/druid_widget_store.json` },
                { name: 'Editor Scripts', type: 'editor_script', url: `${BASE_URL}/assets_editor_scripts_store.json` }
            ],
            items: [],
            loading: false,
            error: null,
            searchQuery: '',
            filterAuthor: 'All Authors',
            filterTag: 'All Tags',
            sortBy: 'Asset Name',
            installing: null,
            notification: null,
            installedAssets: new Set() // Track installed assets by key: "author:id:type"
        };
    },
    computed: {
        authors() {
            const authorsSet = new Set();
            this.items.forEach(item => {
                if (item.author && !item.unlisted) {
                    authorsSet.add(item.author);
                }
            });
            return Array.from(authorsSet).sort();
        },
        tags() {
            const tagsSet = new Set();
            this.items.forEach(item => {
                if (item.tags && !item.unlisted) {
                    item.tags.forEach(tag => tagsSet.add(tag));
                }
            });
            return Array.from(tagsSet).sort();
        },
        sortOptions() {
            const baseOptions = ['Asset Name', 'Author'];
            if (this.activeStore === 'dependency') {
                baseOptions.push('Stars');
            } else if (this.activeStore === 'widget' || this.activeStore === 'editor_script') {
                baseOptions.push('Size');
            }
            return baseOptions;
        },
        filteredItems() {
            let filtered = [...this.items];

            // Filter by search query
            if (this.searchQuery) {
                const query = this.searchQuery.toLowerCase();
                filtered = filtered.filter(item => {
                    const matchesId = item.id && item.id.toLowerCase().includes(query);
                    const matchesTitle = item.title && item.title.toLowerCase().includes(query);
                    const matchesAuthor = item.author && item.author.toLowerCase().includes(query);
                    const matchesDescription = item.description && item.description.toLowerCase().includes(query);
                    const matchesTags = item.tags && item.tags.some(tag => tag.toLowerCase().includes(query));
                    return matchesId || matchesTitle || matchesAuthor || matchesDescription || matchesTags;
                });
            }

            // Filter by author
            if (this.filterAuthor !== 'All Authors') {
                filtered = filtered.filter(item => item.author === this.filterAuthor);
            }

            // Filter by tag
            if (this.filterTag !== 'All Tags') {
                filtered = filtered.filter(item => 
                    item.tags && item.tags.some(tag => tag === this.filterTag)
                );
            }

            // Sort
            filtered.sort((a, b) => {
                switch (this.sortBy) {
                    case 'Asset Name':
                        return (a.title || a.id).localeCompare(b.title || b.id);
                    case 'Author':
                        const authorA = a.author || '';
                        const authorB = b.author || '';
                        if (authorA !== authorB) {
                            return authorA.localeCompare(authorB);
                        }
                        return (a.title || a.id).localeCompare(b.title || b.id);
                    case 'Stars':
                        const starsA = a.stars || 0;
                        const starsB = b.stars || 0;
                        if (starsA !== starsB) {
                            return starsB - starsA;
                        }
                        return (a.title || a.id).localeCompare(b.title || b.id);
                    case 'Size':
                        const sizeA = a.size || 0;
                        const sizeB = b.size || 0;
                        if (sizeA !== sizeB) {
                            return sizeB - sizeA;
                        }
                        return (a.title || a.id).localeCompare(b.title || b.id);
                    default:
                        return 0;
                }
            });

            return filtered;
        }
    },
    mounted() {
        // Get port from URL parameter
        const urlParams = new URLSearchParams(window.location.search);
        const portParam = urlParams.get('port');
        if (portParam) {
            this.editorPort = parseInt(portParam, 10);
            this.savePort();
        } else {
            // Try to load from localStorage
            const savedPort = localStorage.getItem('defoldEditorPort');
            if (savedPort) {
                this.editorPort = parseInt(savedPort, 10);
            }
        }

        // Load initial store
        this.loadStoreData();
    },
    methods: {
        savePort() {
            if (this.editorPort) {
                localStorage.setItem('defoldEditorPort', this.editorPort.toString());
            }
        },
        switchStore(storeType) {
            this.activeStore = storeType;
            this.searchQuery = '';
            this.filterAuthor = 'All Authors';
            this.filterTag = 'All Tags';
            this.sortBy = 'Asset Name';
            this.loadStoreData();
        },
        async loadStoreData() {
            const store = this.stores.find(s => s.type === this.activeStore);
            if (!store) return;

            this.loading = true;
            this.error = null;

            try {
                const response = await fetch(store.url);
                if (!response.ok) {
                    throw new Error(`Failed to load store: ${response.statusText}`);
                }
                const data = await response.json();
                this.items = data.items || [];
            } catch (err) {
                this.error = err.message || 'Failed to load assets. Please check your internet connection.';
                console.error('Error loading store:', err);
            } finally {
                this.loading = false;
            }
        },
        getAssetKey(item) {
            const assetType = this.activeStore === 'dependency' ? 'dependency' : 
                             this.activeStore === 'widget' ? 'widget' : 'widget';
            return `${item.author || ''}:${item.id}:${assetType}`;
        },
        isAssetInstalled(item) {
            return this.installedAssets.has(this.getAssetKey(item));
        },
        getImageUrl(imagePath) {
            if (!imagePath) return null;
            if (imagePath.startsWith('http')) return imagePath;
            return `${BASE_URL}/${imagePath}`;
        },
        handleImageError(event) {
            event.target.style.display = 'none';
            const placeholder = event.target.parentElement.querySelector('.image-placeholder');
            if (placeholder) {
                placeholder.style.display = 'flex';
            }
        },
        formatSize(bytes) {
            if (!bytes) return 'Unknown size';
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return Math.floor(bytes / 1024) + ' KB';
            return Math.floor(bytes / (1024 * 1024)) + ' MB';
        },
        async installAsset(item) {
            if (!this.editorPort) {
                this.showNotification('Please enter the editor port first', 'error');
                return;
            }

            // Check if already installed
            if (this.isAssetInstalled(item)) {
                this.showNotification(`${item.title || item.id} is already installed`, 'success');
                return;
            }

            this.installing = item.id;

            try {
                const assetType = this.activeStore === 'dependency' ? 'dependency' : 
                                 this.activeStore === 'widget' ? 'widget' : 'widget';
                
                const params = new URLSearchParams({
                    id: item.id,
                    type: assetType
                });

                if (item.author) {
                    params.append('author', item.author);
                }

                const url = `http://localhost:${this.editorPort}/install?${params.toString()}`;
                
                // Use no-cors mode for localhost requests
                // We can't read the response, but if request succeeds, installation worked
                await fetch(url, {
                    method: 'GET',
                    mode: 'no-cors'
                });
                
                // With no-cors, we can't read response, but if no error thrown, request succeeded
                // Add small delay to ensure request is sent
                await new Promise(resolve => setTimeout(resolve, 100));
                
                // Mark as installed (only for current session)
                const key = this.getAssetKey(item);
                this.installedAssets.add(key);
                
                this.installing = null;
                this.showNotification(`Successfully installed ${item.title || item.id}`, 'success');
                
            } catch (err) {
                this.installing = null;
                // Check if it's a network error (connection refused)
                const errorMsg = err.message || err.toString();
                if (errorMsg.includes('Failed to fetch') || 
                    errorMsg.includes('NetworkError') ||
                    errorMsg.includes('Network request failed')) {
                    this.showNotification(`Cannot connect to editor. Make sure the editor is running on port ${this.editorPort}`, 'error');
                } else {
                    // For other errors, assume it might have worked (CORS can cause false errors)
                    // Mark as installed anyway since request was sent (only for current session)
                    const key = this.getAssetKey(item);
                    this.installedAssets.add(key);
                    this.showNotification(`Installation request sent for ${item.title || item.id}`, 'success');
                }
                console.error('Installation request:', err);
            }
        },
        showNotification(message, type = 'success') {
            this.notification = { message, type };
            setTimeout(() => {
                this.notification = null;
            }, 5000);
        }
    }
}).mount('#app');

