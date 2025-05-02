import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useApiDemo } from '../hooks/useApiDemo';

export default function HomeScreen() {
  const { data, loading, error } = useApiDemo();
  
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to Your MERN App</Text>
      {loading && <Text>Loading data...</Text>}
      {error && <Text style={styles.error}>Error: {error}</Text>}
      {data && <Text style={styles.data}>Message from API: {data.message}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  data: {
    marginTop: 20,
    fontSize: 16,
  },
  error: {
    color: 'red',
    marginTop: 20,
  },
});
