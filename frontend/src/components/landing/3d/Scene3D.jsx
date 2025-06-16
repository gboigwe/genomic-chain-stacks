// 3D scene setup with lighting, camera, and environment

import React from 'react';
import { OrbitControls } from '@react-three/drei';
import { DNA_COLORS } from './utils/dnaGeometry.js';

/**
 * Scene3D Component
 * Sets up the 3D environment with proper lighting for DNA visualization
 * 
 * @param {React.ReactNode} children - 3D components to render
 * @param {boolean} enableControls - Enable orbit controls for development
 * @param {boolean} autoRotateControls - Auto-rotate camera controls
 * @param {Object} lighting - Custom lighting configuration
 */
const Scene3D = ({ 
  children, 
  enableControls = false,
  autoRotateControls = false,
  lighting = {}
}) => {
  
  // Default lighting configuration based on design
  const defaultLighting = {
    ambient: {
      intensity: 0.3,
      color: DNA_COLORS.DARK_BLUE
    },
    directional: {
      position: [10, 10, 5],
      intensity: 0.8,
      color: DNA_COLORS.WHITE,
      castShadow: true
    },
    point: {
      position: [-10, -10, -5],
      intensity: 0.5,
      color: DNA_COLORS.PRIMARY_TEAL,
      distance: 50,
      decay: 1
    },
    spot: {
      position: [0, 10, 0],
      angle: 0.3,
      penumbra: 0.5,
      intensity: 0.6,
      color: DNA_COLORS.PRIMARY_BLUE,
      castShadow: true,
      distance: 50,
      decay: 1
    }
  };

  // Merge custom lighting with defaults
  const finalLighting = {
    ambient: { ...defaultLighting.ambient, ...lighting.ambient },
    directional: { ...defaultLighting.directional, ...lighting.directional },
    point: { ...defaultLighting.point, ...lighting.point },
    spot: { ...defaultLighting.spot, ...lighting.spot }
  };

  return (
    <>
      {/* Ambient Light - Overall base illumination */}
      <ambientLight 
        intensity={finalLighting.ambient.intensity} 
        color={finalLighting.ambient.color} 
      />
      
      {/* Directional Light - Main lighting (like sun) */}
      <directionalLight 
        position={finalLighting.directional.position}
        intensity={finalLighting.directional.intensity}
        color={finalLighting.directional.color}
        castShadow={finalLighting.directional.castShadow}
        shadow-mapSize-width={2048}
        shadow-mapSize-height={2048}
        shadow-camera-far={50}
        shadow-camera-left={-10}
        shadow-camera-right={10}
        shadow-camera-top={10}
        shadow-camera-bottom={-10}
      />
      
      {/* Point Light - Teal accent lighting */}
      <pointLight 
        position={finalLighting.point.position}
        intensity={finalLighting.point.intensity}
        color={finalLighting.point.color}
        distance={finalLighting.point.distance}
        decay={finalLighting.point.decay}
      />
      
      {/* Spot Light - Blue focused lighting */}
      <spotLight
        position={finalLighting.spot.position}
        angle={finalLighting.spot.angle}
        penumbra={finalLighting.spot.penumbra}
        intensity={finalLighting.spot.intensity}
        color={finalLighting.spot.color}
        castShadow={finalLighting.spot.castShadow}
        distance={finalLighting.spot.distance}
        decay={finalLighting.spot.decay}
        shadow-mapSize-width={1024}
        shadow-mapSize-height={1024}
      />
      
      {/* Additional accent lights for glow effect */}
      <pointLight 
        position={[5, 0, 5]}
        intensity={0.3}
        color={DNA_COLORS.CYAN}
        distance={20}
        decay={2}
      />
      
      <pointLight 
        position={[-5, 0, -5]}
        intensity={0.3}
        color={DNA_COLORS.GLOW_TEAL}
        distance={20}
        decay={2}
      />

      {/* Render children (DNA components) */}
      {children}
      
      {/* Optional: OrbitControls for development/testing */}
      {enableControls && (
        <OrbitControls 
          enableZoom={true}
          enablePan={true}
          autoRotate={autoRotateControls}
          autoRotateSpeed={1}
          enableDamping
          dampingFactor={0.05}
          minDistance={2}
          maxDistance={20}
          minPolarAngle={Math.PI / 6}
          maxPolarAngle={Math.PI - Math.PI / 6}
        />
      )}
    </>
  );
};

export default Scene3D;
