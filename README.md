# MERN Stack React Native Project

## 📱 Project Overview

This project is a full-stack mobile application built with the MERN stack (MongoDB, Express, React Native, Node.js) organized as a monorepo. This structure allows us to maintain all code in a single repository while keeping clear boundaries between frontend, backend, and shared code.

## 🚀 Getting Started

### Prerequisites

- Node.js (v18 or higher)
- Yarn or npm
- MongoDB (local installation or MongoDB Atlas account)
- Expo CLI (`npm install -g expo-cli`)

### Installation Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/DiAndyW/35LProj.git
   cd your-repo-name
   ```

2. Install dependencies:
   ```bash
   yarn install
   # OR
   npm install
   ```

3. Set up environment variables:
   - Copy `.env.example` to `.env` in both `client` and `server` directories
   - Update the variables with your specific configuration

4. Start development servers:
   ```bash
   yarn dev
   # OR
   npm run dev
   ```

## 📂 Project Structure Explained

Our project uses a monorepo structure with three main packages:

```
project-root/
├── client/           # React Native frontend
├── server/           # Express/Node.js backend
└── shared/           # Shared code between client and server
```

### Client (React Native App)

```
client/
├── src/
│   ├── assets/       # Images, fonts, and other static files
│   ├── components/   # Reusable UI components
│   ├── screens/      # Screen components (full pages)
│   ├── navigation/   # Navigation configuration
│   ├── services/     # API client and service functions
│   ├── hooks/        # Custom React hooks
│   ├── store/        # State management (Redux/Context)
│   ├── utils/        # Helper functions and utilities
│   └── types/        # TypeScript type definitions
├── app.json          # Expo configuration
└── package.json      # Client dependencies
```

**Key Points:**
- **Components** vs **Screens**: Components are reusable UI elements, while screens represent full pages in the app
- **Services**: Handle all API communication with the backend
- **Hooks**: Custom hooks for reusable logic, like data fetching
- **Navigation**: Contains the app's navigation structure using React Navigation

### Server (Express/Node.js API)

```
server/
├── src/
│   ├── config/       # Configuration files
│   ├── controllers/  # Request handlers
│   ├── middleware/   # Express middleware
│   ├── models/       # Mongoose data models
│   ├── routes/       # API route definitions
│   ├── services/     # Business logic
│   ├── utils/        # Helper functions
│   └── types/        # TypeScript type definitions
└── package.json      # Server dependencies
```

**Key Points:**
- **Controllers**: Handle HTTP requests and responses
- **Models**: Define database schemas using Mongoose
- **Services**: Contain the core business logic
- **Routes**: Define API endpoints and connect them to controllers
- **Middleware**: Functions that run during the request lifecycle

### Shared Code

```
shared/
├── constants/        # Shared constants (API routes, etc.)
├── types/            # Shared TypeScript interfaces
├── utils/            # Shared utility functions
└── validation/       # Shared validation schemas
```

**Key Points:**
- This package contains code used by both client and server
- It helps maintain consistency across the application
- Changes here affect both frontend and backend

## 📦 Understanding Dependencies

### Workspace Management

This project uses workspaces to manage dependencies across packages:

- **Root `package.json`**: Contains dev dependencies for the entire project and workspace configuration
- **Package-specific `package.json`**: Contains dependencies specific to that package

### Key Dependencies

#### Client (React Native)
- **React Native**: Mobile app framework
- **Expo**: Tool suite for React Native development
- **React Navigation**: Navigation library
- **Axios**: HTTP client for API requests

#### Server (Express/Node.js)
- **Express**: Web framework for Node.js
- **Mongoose**: MongoDB object modeling
- **Cors**: Middleware for handling CORS
- **Dotenv**: Environment variable management

#### Development Dependencies
- **TypeScript**: Type safety for JavaScript
- **Jest**: Testing framework
- **ESLint/Prettier**: Code quality and formatting

### Adding Dependencies

To add a dependency to a specific package:

```bash
# For client
yarn workspace client add package-name
# OR
npm install package-name --workspace=client

# For server
yarn workspace server add package-name
# OR
npm install package-name --workspace=server

# For shared
yarn workspace shared add package-name
# OR
npm install package-name --workspace=shared
```

## 🔄 Development Workflow

### Starting Development Servers

```bash
# Start both client and server
yarn dev
# OR
npm run dev

# Start only client
yarn client
# OR
npm run client

# Start only server
yarn server
# OR
npm run server
```

### Database Connection

The server connects to MongoDB using the connection string in the `.env` file:

```
MONGODB_URI=mongodb://localhost:27017/your-database-name
```

You can use a local MongoDB instance or a cloud-based MongoDB Atlas connection string.

### API Communication

The React Native app communicates with the Express backend through API calls:

1. API routes are defined in `server/src/routes`
2. Client services in `client/src/services` make HTTP requests to these routes
3. Shared constants in `shared/constants` help keep API URLs consistent

## 🧪 Testing

### Running Tests

```bash
# Run all tests
yarn test
# OR
npm test

# Run only client tests
yarn workspace client test
# OR
npm test --workspace=client

# Run only server tests
yarn workspace server test
# OR
npm test --workspace=server
```

### Test Structure

- **Client**: Tests are located in `client/__tests__`
- **Server**: Tests are located in `server/tests`

## 📝 Code Style and Conventions

### Naming Conventions

- **Folders**: lowercase with hyphens (e.g., `auth-utils`)
- **Files**:
  - React components: PascalCase (e.g., `UserProfile.tsx`)
  - Utilities/services: camelCase (e.g., `apiService.ts`)
- **Variables/Functions**: camelCase
- **Components**: PascalCase
- **Interfaces/Types**: PascalCase with descriptive names

### Import Order

1. External libraries
2. Shared code
3. Local imports, sorted by path depth

Example:
```typescript
// External libraries
import React, { useState } from 'react';
import { View, Text } from 'react-native';

// Shared code
import { User } from '@shared/types';

// Local imports
import { fetchUser } from '../services/userService';
import UserAvatar from '../components/UserAvatar';
```

## 🔒 Authentication Flow

Our application uses JWT (JSON Web Tokens) for authentication:

1. User registers/logs in through client
2. Server validates credentials and returns a JWT
3. Client stores the JWT and includes it in subsequent API requests
4. Server middleware validates the JWT on protected routes

JWT management is handled by:
- Client: `client/src/services/authService.ts`
- Server: `server/src/middleware/auth.middleware.ts`

## 🧠 State Management

We use React Context API for state management:

- Global contexts are in `client/src/store`
- Each context includes a provider, actions, and state

For complex applications, we may transition to Redux, which would be organized as:
- `client/src/store/reducers`
- `client/src/store/actions`
- `client/src/store/selectors`

## 📋 Common Tasks for New Developers

### Creating a New Screen

1. Create a new file in `client/src/screens`
2. Import and use components from `client/src/components`
3. Add the screen to navigation in `client/src/navigation`

### Adding an API Endpoint

1. Create/update a model in `server/src/models`
2. Create a controller in `server/src/controllers`
3. Define routes in `server/src/routes`
4. Add the API constant to `shared/constants`
5. Create/update the service in `client/src/services`

### Working with Shared Code

1. Add your code to the appropriate directory in `shared/`
2. Export it from the relevant index file
3. Import in client or server using workspace references

## ⚠️ Common Pitfalls

- **Missing `.gitkeep` files**: Empty directories won't be committed to Git unless they contain a file
- **Incorrect imports**: Use proper paths when importing from other workspaces
- **Environment variables**: Make sure to set up all required env variables
- **Dependency conflicts**: Be careful of version mismatches between workspaces

## 🤝 Contributing

1. Pull latest changes from the main branch
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Run tests: `yarn test`
5. Commit changes: `git commit -m "Description of changes"`
6. Push to your branch: `git push origin feature/your-feature-name`
7. Create a pull request

## 🔍 Additional Resources

- [React Native Documentation](https://reactnative.dev/docs/getting-started)
- [Expo Documentation](https://docs.expo.dev/)
- [Express.js Documentation](https://expressjs.com/)
- [Mongoose Documentation](https://mongoosejs.com/docs/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## 📞 Need Help?

If you're stuck or have questions:
1. Check existing documentation
2. Look for similar issues in our GitHub repository
3. Ask a team member for help
4. Create a new issue on GitHub with a detailed description

---

Happy coding! 🚀
