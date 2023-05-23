/* tslint:disable */
/* eslint-disable */
/**
/* This file was automatically generated from pydantic models by running pydantic2ts.
/* Do not modify it by hand - just update the pydantic models and then re-run the script
*/

export type Analysis = "speedmap" | "hqta_areas" | "hqta_stops";

export interface BasemapConfig {
  url: string;
  options: {
    [k: string]: unknown;
  };
}
/**
 * Feature Model
 */
export interface FeaturePointHQTA {
  type: "Feature";
  geometry: Point;
  properties: HQTA;
  id?: number | string;
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
/**
 * Point Model
 */
export interface Point {
  type: "Point";
  coordinates: [number, number] | [number, number, number];
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
export interface HQTA {
  hqta_type: string;
  agency_name_primary: string;
  agency_name_secondary?: string;
}
/**
 * Feature Model
 */
export interface FeaturePolygonSpeedmap {
  type: "Feature";
  geometry: Polygon;
  properties: Speedmap;
  id?: number | string;
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
/**
 * Polygon Model
 */
export interface Polygon {
  type: "Polygon";
  coordinates: [
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    ...([number, number] | [number, number, number])[]
  ][];
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
export interface Speedmap {
  stop_id?: string;
  stop_name?: string;
  route_id?: string;
  tooltip: Tooltip;
  color: number[];
  highlight_color?: number[];
}
export interface Tooltip {
  html: string;
  style?: {
    [k: string]: unknown;
  };
}
/**
 * Feature Model
 */
export interface FeatureUnionPolygonMultiPolygonHQTA {
  type: "Feature";
  geometry: Polygon | MultiPolygon;
  properties: HQTA;
  id?: number | string;
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
/**
 * MultiPolygon Model
 */
export interface MultiPolygon {
  type: "MultiPolygon";
  coordinates: [
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    [number, number] | [number, number, number],
    ...([number, number] | [number, number, number])[]
  ][][];
  bbox?: [number, number, number, number] | [number, number, number, number, number, number];
}
export interface Layer {
  name: string;
  url: string;
  analysis?: Analysis;
}
export interface State {
  name?: string;
  /**
   * @minItems 1
   */
  layers: [Layer, ...Layer[]];
  lat_lon?: [number, number] | [number, number, number];
  zoom?: number;
  /**
   * @minItems 2
   * @maxItems 2
   */
  bbox?: [[number, number] | [number, number, number], [number, number] | [number, number, number]];
  basemap_config?: BasemapConfig;
}
