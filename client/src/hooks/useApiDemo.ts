import { useState, useEffect } from 'react';
import axios from 'axios';

export function useApiDemo() {
  const [data, setData] = useState<{ message: string } | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        // Replace with your actual API URL in development
        const response = await axios.get('http://localhost:5000/api/hello');
        setData(response.data);
        setError(null);
      } catch (err) {
        setError('Failed to fetch data from API');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  return { data, loading, error };
}
