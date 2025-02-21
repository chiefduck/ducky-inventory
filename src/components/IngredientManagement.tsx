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
      const { data: ingredientsData, error: ingredientsError } = await supabase
        .from('ingredients')
        .select(`
          id,
          name,
          moq,
          unit,
          part_number,
          current_price,
          supplier:suppliers (
            id,
            name
          )
        `)
        .order('name');

      if (ingredientsError) throw ingredientsError;
      setIngredients(ingredientsData);
    } catch (error) {
      console.error('Error loading ingredients:', error);
      toast.error('Failed to load ingredients');
    } finally {
      setLoading(false);
    }
  }

  const handlePriceChange = (ingredientId: string, value: string) => {
    const newPrice = value === '' ? null : parseFloat(value);
    setIngredients(prev =>
      prev.map(ing =>
        ing.id === ingredientId ? { ...ing, unsavedPrice: newPrice } : ing
      )
    );
    setHasUnsavedChanges(true);
  };

  const handleInventoryChange = (ingredientId: string, value: string) => {
    const newLevel = value === '' ? 0 : parseFloat(value);
    setIngredients(prev =>
      prev.map(ing =>
        ing.id === ingredientId ? { ...ing, unsavedLevel: newLevel } : ing
      )
    );
    setHasUnsavedChanges(true);
  };

  const handleSaveChanges = async () => {
    try {
      for (const ingredient of ingredients) {
        if (ingredient.unsavedPrice !== undefined) {
          await supabase
            .from('ingredients')
            .update({ current_price: ingredient.unsavedPrice })
            .eq('id', ingredient.id);
        }
        if (ingredient.unsavedLevel !== undefined) {
          await supabase
            .from('inventory_levels')
            .upsert({
              ingredient_id: ingredient.id,
              current_level: ingredient.unsavedLevel,
            }, { onConflict: 'ingredient_id' });
        }
      }
      setHasUnsavedChanges(false);
      toast.success('Inventory and prices updated successfully');
      loadIngredients();
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
        <h2 className="text-lg font-semibold text-gray-900">Ingredient Management</h2>
        <button
          onClick={handleSaveChanges}
          disabled={!hasUnsavedChanges}
          className={`inline-flex items-center px-4 py-2 text-sm font-medium rounded-md ${
            hasUnsavedChanges ? 'text-white bg-indigo-600 hover:bg-indigo-700' : 'text-gray-400 bg-gray-100 cursor-not-allowed'
          }`}
        >
          Save Changes
        </button>
      </div>

      <table className="min-w-full divide-y divide-gray-200">
        <thead>
          <tr>
            <th>Ingredient</th>
            <th>Supplier</th>
            <th>Part Number</th>
            <th>MOQ</th>
            <th>Price</th>
            <th>Stock</th>
          </tr>
        </thead>
        <tbody>
          {ingredients.map(ingredient => (
            <tr key={ingredient.id}>
              <td>{ingredient.name}</td>
              <td>{ingredient.supplier.name}</td>
              <td>{ingredient.part_number || 'N/A'}</td>
              <td>{ingredient.moq} {ingredient.unit}</td>
              <td>
                <input
                  type="number"
                  step="0.01"
                  value={ingredient.unsavedPrice ?? ingredient.current_price ?? ''}
                  onChange={(e) => handlePriceChange(ingredient.id, e.target.value)}
                />
              </td>
              <td>
                <input
                  type="number"
                  value={ingredient.unsavedLevel ?? ingredient.current_level ?? ''}
                  onChange={(e) => handleInventoryChange(ingredient.id, e.target.value)}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
