import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { Calculator, ChevronDown, ChevronRight } from 'lucide-react';

interface Ingredient {
  id: string;
  name: string;
  percentage: number;
  density: number;
  base_requirement: number;
  moq: number;
  unit: string;
  supplier: {
    name: string;
    id: string;
  };
  current_level?: number;
  current_price?: number;
  part_number?: string;
  batch_requirement?: number;
}

interface InventoryFormProps {
  flavorId: string;
  batchSize: number;
  calculating: boolean;
  onCalculate: (ingredients: Ingredient[]) => void;
}

export function InventoryForm({ flavorId, batchSize, calculating, onCalculate }: InventoryFormProps) {
  const [ingredients, setIngredients] = useState<Ingredient[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set());
  const [baseBatchSize, setBaseBatchSize] = useState<number>(500);
  const [error, setError] = useState<string | null>(null);

  const toggleRow = (ingredientId: string) => {
    setExpandedRows(prev => {
      const next = new Set(prev);
      if (next.has(ingredientId)) {
        next.delete(ingredientId);
      } else {
        next.add(ingredientId);
      }
      return next;
    });
  };

  // Function to calculate ingredient weight
  const calculateIngredientWeight = (percentage: number, density: number): number => {
    const defaultDensity = density || 8.450; // Use default density if not specified
    return Number((batchSize * defaultDensity * (percentage / 100)).toFixed(3));
  };

  // Update ingredient requirements when batch size changes
  useEffect(() => {
    setIngredients(prev => prev.map(ingredient => ({
      ...ingredient,
      batch_requirement: calculateIngredientWeight(ingredient.percentage, ingredient.density)
    })));
  }, [batchSize]);

  useEffect(() => {
    async function loadIngredients() {
      try {
        setError(null);
        setLoading(true);
        
        // Get the current user
        const { data: { user } } = await supabase.auth.getUser();

        const { data: flavorData, error: flavorError } = await supabase
          .from('flavors')
          .select('base_batch_size_gallons')
          .eq('id', flavorId)
          .single();

        if (flavorError) throw flavorError;
        if (flavorData) {
          setBaseBatchSize(flavorData.base_batch_size_gallons);
        }

        const { data: flavorIngredients, error } = await supabase
          .from('flavor_ingredients')
          .select(
            'ingredient_id, batch_requirement, percentage, density, ingredients (id, name, moq, unit, part_number, supplier:suppliers (id, name))'
          )
          .eq('flavor_id', flavorId);

        if (error) throw error;

        if (!flavorIngredients || flavorIngredients.length === 0) {
          setError('No ingredients found for this flavor');
          setIngredients([]);
          return;
        }

        // Load current inventory levels
        const { data: inventoryLevels, error: inventoryError } = await supabase
          .from('inventory_levels')
          .select('ingredient_id, current_level')
          .eq('user_id', user.id);

        if (inventoryError) throw inventoryError;

        const formattedIngredients = flavorIngredients.map((fi) => ({
          id: fi.ingredients.id,
          name: fi.ingredients.name,
          base_requirement: fi.batch_requirement || 0,
          flavor_id: flavorId,
          percentage: fi.percentage || 0,
          density: fi.density || (fi.ingredients.name === 'Filtered Water' ? 8.345 : 8.450),
          moq: fi.ingredients.moq,
          unit: fi.ingredients.unit,
          supplier: fi.ingredients.supplier,
          part_number: fi.ingredients.part_number,
          batch_requirement: calculateIngredientWeight(fi.percentage || 0, fi.density || (fi.ingredients.name === 'Filtered Water' ? 8.345 : 8.450)),
          current_level: inventoryLevels?.find(il => il.ingredient_id === fi.ingredients.id)?.current_level || 0,
        }));

        setIngredients(formattedIngredients);
      } catch (error) {
        console.error('Error loading ingredients:', error);
        setError('Failed to load ingredients. Please try again later.');
        setIngredients([]);
      } finally {
        setLoading(false);
      }
    }

    if (flavorId) {
      loadIngredients();
    }
  }, [flavorId]); // 🔥 Only reload when flavorId changes

  function handleInventoryChange(ingredientId: string, value: string) {
    const newLevel = value === '' ? 0 : parseFloat(value);
    setIngredients(prev => prev.map(ing => 
      ing.id === ingredientId ? { ...ing, current_level: newLevel } : ing
    ));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    const user = await supabase.auth.getUser();
    if (!user.data.user) {
      toast.error('You must be logged in to update inventory');
      return;
    }

    try {
      const { error } = await supabase
        .from('inventory_levels')
        .upsert(
          ingredients.map((ing) => ({
            ingredient_id: ing.id,
            user_id: user.data.user.id,
            current_level: ing.current_level || 0,
          })),
          { onConflict: 'ingredient_id,user_id' }
        );

      if (error) throw error;

      onCalculate(ingredients);
      toast.success('Inventory updated successfully');
    } catch (error) {
      console.error('Error updating inventory:', error);
      toast.error('Failed to update inventory. Please try again.');
    }
  }

  function renderContent() {
    if (loading) {
      return (
        <div className="flex justify-center py-8">
          <Calculator className="animate-spin h-8 w-8" />
        </div>
      );
    }

    if (error) {
      return (
        <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
          <p className="text-sm text-yellow-700">{error}</p>
        </div>
      );
    }

    return (
      <>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg p-6">
          <h3 className="text-sm font-medium text-gray-900 mb-4">Batch Information</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Total Batch Size</label>
              <div className="mt-1 text-2xl font-bold text-indigo-600">{batchSize} Gallons</div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Total Cans</label>
              <div className="mt-1 text-2xl font-bold text-indigo-600">
                {Math.floor(batchSize * 128 / 12)} cans
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Based on 12oz cans
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg p-6">
          <h3 className="text-sm font-medium text-gray-900 mb-4">Recipe Summary</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Total Ingredients</label>
              <div className="mt-1 text-2xl font-bold text-indigo-600">{ingredients.length}</div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Ingredients Below Stock</label>
              <div className="mt-1 text-2xl font-bold text-red-600">
                {ingredients.filter(ing => (ing.current_level || 0) < ing.batch_requirement).length}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg overflow-x-auto">
        <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
          <h3 className="text-sm font-medium text-gray-900">Recipe Requirements</h3>
          <div className="flex items-center space-x-2 text-sm text-gray-500">
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
              Needs Order
            </span>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
              Sufficient
            </span>
          </div>
        </div>
        <table className="min-w-full divide-y divide-gray-200">
          <thead>
            <tr className="bg-gray-50">
              <th className="w-8 px-2 py-3"></th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ingredient</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Need
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Have
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {ingredients.map((ingredient) => [
              <tr 
                key={ingredient.id} 
                className={`hover:bg-gray-50 ${
                  (ingredient.current_level || 0) < ingredient.batch_requirement 
                    ? 'bg-red-50/50' 
                    : ''
                } cursor-pointer`}
                onClick={() => toggleRow(ingredient.id)}
              >
                <td className="w-8 px-2 py-4">
                  {expandedRows.has(ingredient.id) ? (
                    <ChevronDown className="w-4 h-4 text-gray-400" />
                  ) : (
                    <ChevronRight className="w-4 h-4 text-gray-400" />
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="flex flex-col">
                    <span className="text-sm font-medium text-gray-900">{ingredient.name}</span>
                    <span className="text-xs text-gray-500 flex items-center gap-2">
                      {(ingredient.current_level || 0) < ingredient.batch_requirement ? (
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">
                          Needs Order
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                          Sufficient
                        </span>
                      )}
                      <span>•</span>
                      <span>{ingredient.percentage}%</span>
                    </span>
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {ingredient.batch_requirement.toFixed(2)} {ingredient.unit}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  <div className="flex items-center space-x-2">
                    <input
                      type="number"
                      step="0.01"
                      value={ingredient.current_level || ''}
                      onChange={(e) => handleInventoryChange(ingredient.id, e.target.value)}
                      className={`block w-24 rounded-md shadow-sm focus:ring-indigo-500 sm:text-sm ${
                        (ingredient.current_level || 0) < ingredient.batch_requirement
                          ? 'border-red-300 text-red-900 focus:border-red-500'
                          : 'border-gray-300 focus:border-indigo-500'
                      }`}
                      placeholder="0.00"
                    />
                    <span>{ingredient.unit}</span>
                  </div>
                </td>
              </tr>,
              expandedRows.has(ingredient.id) && (
                <tr key={`${ingredient.id}-details`} className="bg-gray-50/50">
                  <td></td>
                  <td colSpan={3} className="px-6 py-4">
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Supplier Information</h4>
                        <dl className="space-y-1">
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Supplier:</dt>
                            <dd className="text-gray-900">{ingredient.supplier.name}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Part Number:</dt>
                            <dd className="text-gray-900">{ingredient.part_number || 'N/A'}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">MOQ:</dt>
                            <dd className="text-gray-900">{ingredient.moq} {ingredient.unit}</dd>
                          </div>
                        </dl>
                      </div>
                    </div>
                  </td>
                </tr>
              )
            ])}
          </tbody>
        </table>
      </div>
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={calculating}
          className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {calculating ? (
            <>
              <Calculator className="w-5 h-5 mr-2 animate-spin" />
              Calculating...
            </>
          ) : (
            <>
              <Calculator className="w-5 h-5 mr-2" />
              Calculate Order
            </>
          )}
        </button>
      </div>
      </>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">Recipe Calculator</h2>
        <p className="mt-1 text-sm text-gray-500">
          Calculate ingredient requirements based on batch size and current inventory.
        </p>
      </div>

      {renderContent()}
    </form>
  );
}