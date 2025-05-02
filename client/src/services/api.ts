import axios from 'axios';

// Default config for the axios instance
const axiosParams = {
  // Set different base URL based on the environment
  baseURL: process.env.NODE_ENV === 'development' 
    ? 'http://localhost:5000/api' 
    : 'https://yourapi.com/api',
};

// Create axios instance with default params
const axiosInstance = axios.create(axiosParams);

// Main api function
const api = (axios: any) => {
  return {
    get: <T>(url: string, config: any = {}) => 
      axios.get<T>(url, config),
    delete: <T>(url: string, config: any = {}) => 
      axios.delete<T>(url, config),
    post: <T>(url: string, body: any = {}, config: any = {}) => 
      axios.post<T>(url, body, config),
    patch: <T>(url: string, body: any = {}, config: any = {}) => 
      axios.patch<T>(url, body, config),
    put: <T>(url: string, body: any = {}, config: any = {}) => 
      axios.put<T>(url, body, config),
  };
};

export default api(axiosInstance);
