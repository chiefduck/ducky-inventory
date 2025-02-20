import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Package } from 'lucide-react';
import toast from 'react-hot-toast';

interface Ingredient {
  id: string;
  name: string;
  moq: number;
  unit: string;
  supplier: {
    name: string;
    id: string;
  };
  part_number?: string;
  current_price?: number;
  current_level?: number;
  unsavedPrice?: number;
  unsavedLevel?: number;
}

export function IngredientManagement() {
  const [ingredients, setIngredients] = useState<Ingredient[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  useEffect(() => {
    loadIngredients();
  }, []);

  async function loadIngredients() {
    try {
      setLoading(true);

      // Load ingredients with their current prices and inventory levels
      const { data: ingredientsData, error: ingredientsError } = await supabase
        .from('ingredients')
        .select(`
          id,
          name,
          moq,
          unit,
          part_number,
          supplier:suppliers (
            id,
            name
          )
        `)
        .order('name');

      if (ingredientsError) throw ingredientsError;

      if (ingredientsData) {
        // Get the current user
        const { data: { user } } = await supabase.auth.getUser();
        
        if (user) {
          // Load current inventory levels
          const { data: inventoryLevels } = await supabase
            .from('inventory_levels')
            .select('ingredient_id, current_level')
            .eq('user_id', user.id);

          // Load current prices from localStorage
          const storedPrices = JSON.parse(localStorage.getItem('ingredientPrices') || '{}');

          // Combine all data
          const enrichedIngredients = ingredientsData.map(ingredient => ({
            ...ingredient,
            current_level: inventoryLevels?.find(il => il.ingredient_id === ingredient.id)?.current_level || 0,
            current_price: storedPrices[ingredient.id] || null,
            unsavedPrice: storedPrices[ingredient.id] || null,
            unsavedLevel: inventoryLevels?.find(il => il.ingredient_id === ingredient.id)?.current_level || 0
          }));

          setIngredients(enrichedIngredients);
        }
      }
    } catch (error) {
      console.error('Error loading ingredients:', error);
      toast.error('Failed to load ingredients');
    } finally {
      setLoading(false);
    }
  }

  const handlePriceChange = (ingredientId: string, value: string) => {
    const newPrice = value === '' ? null : parseFloat(value);
    
    // Update state
    setIngredients(prev => 
      prev.map(ing => 
        ing.id === ingredientId 
          ? { ...ing, unsavedPrice: newPrice } 
          : ing
      )
    );
    setHasUnsavedChanges(true);
  };

  const handleInventoryChange = (ingredientId: string, value: string) => {
    const newLevel = value === '' ? 0 : parseFloat(value);
    
    setIngredients(prev => 
      prev.map(ing => 
        ing.id === ingredientId 
          ? { ...ing, unsavedLevel: newLevel } 
          : ing
      )
    );
    setHasUnsavedChanges(true);
  };

  const handleSaveChanges = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        toast.error('You must be logged in to update inventory');
        return;
      }

      // Save inventory levels
      const { error } = await supabase
        .from('inventory_levels')
        .upsert(ingredients.map(ing => ({
          ingredient_id: ing.id,
          user_id: user.id,
          current_level: ing.unsavedLevel
        })), {
          onConflict: 'ingredient_id,user_id'
        });

      if (error) throw error;

      // Save prices to localStorage
      const updatedPrices = ingredients.reduce((acc, ing) => ({
        ...acc,
        [ing.id]: ing.unsavedPrice
      }), {});
      localStorage.setItem('ingredientPrices', JSON.stringify(updatedPrices));

      // Update state with saved values
      setIngredients(prev => 
        prev.map(ing => ({
          ...ing,
          current_level: ing.unsavedLevel,
          current_price: ing.unsavedPrice
        })
        )
      );

      setHasUnsavedChanges(false);
      toast.success('Inventory updated successfully');
    } catch (error) {
      console.error('Error updating inventory:', error);
      toast.error('Failed to update inventory');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <Package className="animate-spin h-8 w-8" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">Ingredient Management</h2>
          <p className="mt-1 text-sm text-gray-500 max-w-2xl">
            Update prices and inventory levels for all ingredients. Make your changes and click Save to update the values. These will be used when calculating orders for specific flavors.
          </p>
        </div>
        <button
          onClick={handleSaveChanges}
          disabled={!hasUnsavedChanges}
          className={`
            inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm
            ${hasUnsavedChanges
              ? 'text-white bg-indigo-600 hover:bg-indigo-700'
              : 'text-gray-400 bg-gray-100 cursor-not-allowed'
            }
          `}
        >
          Save Changes
        </button>
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead>
            <tr className="bg-gray-50">
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Part #
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Ingredient
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Supplier
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                MOQ
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Current Price/lb
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Current Stock
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {ingredients.map((ingredient) => (
              <tr key={ingredient.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {ingredient.part_number || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {ingredient.name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {ingredient.supplier.name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {ingredient.moq} {ingredient.unit}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <div className="flex items-center space-x-2">
                    <span>$</span>
                    <input
                      type="number"
                      step="0.01"
                      value={ingredient.unsavedPrice ?? ''}
                      onChange={(e) => handlePriceChange(ingredient.id, e.target.value)}
                      className="block w-24 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="0.00"
                    />
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <div className="flex items-center space-x-2">
                    <input
                      type="number"
                      step="0.01"
                      value={ingredient.unsavedLevel ?? ''}
                      onChange={(e) => handleInventoryChange(ingredient.id, e.target.value)}
                      className="block w-24 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="0.00"
                    />
                    <span>{ingredient.unit}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}