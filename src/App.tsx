import React, { useState, useEffect } from 'react';
import { Auth } from './components/Auth';
import { FlavorSelection } from './components/FlavorSelection';
import { InventoryForm } from './components/InventoryForm';
import { OrderSummary } from './components/OrderSummary';
import { IngredientManagement } from './components/IngredientManagement';
import { BatchSettings } from './components/BatchSettings';
import { supabase } from './lib/supabase';
import toast, { Toaster } from 'react-hot-toast';
import { GlassWater, LogOut, Settings as SettingsIcon, Package } from 'lucide-react';

interface OrderItem {
  name: string;
  supplier: {
    name: string;
  };
  batch_requirement: number;
  current_level: number;
  orderQuantity: number;
  pailsNeeded: number;
  totalOrdered: number;
  totalCost: number;
  unit: string;
  moq: number;
  part_number?: string;
}

interface BatchCosts {
  can_cost_per_unit: number;
  tolling_cost_per_batch: number;
}

interface BatchSize {
  size_gallons: number;
  cans_per_batch: number;
}

interface FreightCost {
  supplier_id: string;
  cost: number;
}

function App() {
  const [session, setSession] = useState(null);
  const [selectedFlavorId, setSelectedFlavorId] = useState<string | null>(null);
  const [orderItems, setOrderItems] = useState<OrderItem[]>([]);
  const [activeTab, setActiveTab] = useState<'flavors' | 'ingredients' | 'settings'>('ingredients');
  const [showSettings, setShowSettings] = useState(false);
  const [batchCosts, setBatchCosts] = useState<{
    can_cost_per_unit: number;
    tray_cost_per_unit: number;
    paktech_cost_per_unit: number;
    can_end_cost_per_unit: number;
    storage_cost_per_unit: number;
    tolling_cost_per_gallon: number;
  } | null>(null);
  const [batchSize, setBatchSize] = useState<BatchSize | null>(null);
  const [currentBatchSize, setCurrentBatchSize] = useState<number>(500);
  const [freightCosts, setFreightCosts] = useState<FreightCost[]>([]);
  const [calculatingOrder, setCalculatingOrder] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (session) {
      loadCostSettings();
    }
  }, [session]);

  // Clear order items when flavor changes
  useEffect(() => {
    setOrderItems([]);
  }, [selectedFlavorId]);

  const loadCostSettings = async () => {
    try {
      // Load batch costs
      const { data: batchCostsData, error: batchCostsError } = await supabase
        .from('batch_costs')
        .select('*')
        .limit(1);

      if (batchCostsError) throw batchCostsError;
      if (batchCostsData && batchCostsData.length > 0) {
        setBatchCosts(batchCostsData[0]);
      } else {
        // Insert default batch costs if none exist
        const { data: newCostsData, error: insertError } = await supabase
          .from('batch_costs')
          .insert([{
            can_cost_per_unit: 0,
            can_end_cost_per_unit: 0,
            tray_cost_per_unit: 0,
            paktech_cost_per_unit: 0,
            storage_cost_per_unit: 0,
            tolling_cost_per_gallon: 0
          }])
          .select()
          .single();

        if (insertError) throw insertError;
        setBatchCosts(newCostsData);
      }

      // Load batch size
      const { data: sizeData, error: sizeError } = await supabase
        .from('batch_sizes')
        .select('*')
        .limit(1);

      if (sizeError) throw sizeError;
      if (sizeData && sizeData.length > 0) {
        setBatchSize(sizeData[0]);
      } else {
        // Insert default batch size if none exist
        const { data: newSizeData, error: insertError } = await supabase
          .from('batch_sizes')
          .insert([{ size_gallons: 500, cans_per_batch: 4000 }])
          .select()
          .single();

        if (insertError) throw insertError;
        setBatchSize(newSizeData);
      }

      // Load freight costs
      const { data: freightData, error: freightError } = await supabase
        .from('freight_costs')
        .select('*');

      if (freightError) throw freightError;
      if (freightData) {
        setFreightCosts(freightData);
      }
    } catch (error) {
      console.error('Error loading cost settings:', error);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  const calculateOrder = async (ingredients) => {
    try {
      setCalculatingOrder(true);

      // Load all pricing tiers for the ingredients
      const { data: pricingTiers, error: pricingError } = await supabase
        .from('pricing_tiers')
        .select('*')
        .in(
          'ingredient_id',
          ingredients.map((i) => i.id)
        )
        .order('min_quantity', { ascending: false });

      if (pricingError) {
        console.error('Error loading pricing tiers:', pricingError);
        throw pricingError;
      }

      const calculatedItems = ingredients.map((ingredient) => {
        const orderQuantity = Math.max(
          0,
          ingredient.batch_requirement - ingredient.current_level
        );
        
        // If we have surplus, return zero cost values
        if (orderQuantity === 0) {
          return {
            name: ingredient.name,
            supplier: ingredient.supplier,
            batch_requirement: ingredient.batch_requirement,
            current_level: ingredient.current_level,
            orderQuantity: 0,
            pailsNeeded: 0,
            totalOrdered: 0,
            totalCost: 0,
            unit: ingredient.unit,
            moq: ingredient.moq,
            supplier_id: ingredient.supplier.id,
            part_number: ingredient.part_number,
            has_surplus: true,
            cost_per_can: 0
          };
        }

        const pailsNeeded = Math.ceil(orderQuantity / ingredient.moq);
        const totalOrdered = pailsNeeded * ingredient.moq;

        // Get all pricing tiers for this ingredient
        const ingredientTiers = pricingTiers.filter(
          (pt) => pt.ingredient_id === ingredient.id
        );
        
        // Find the applicable tier based on total ordered quantity
        const applicableTier = ingredientTiers.find(
          (tier) => totalOrdered >= tier.min_quantity
        );

        // Calculate price per unit
        const pricePerUnit = ingredient.current_price || applicableTier?.price_per_unit || 0;
        
        // If no price is set, return values but mark as no price
        if (pricePerUnit === 0) {
          return {
            name: ingredient.name,
            supplier: ingredient.supplier,
            batch_requirement: ingredient.batch_requirement,
            current_level: ingredient.current_level,
            orderQuantity,
            pailsNeeded,
            totalOrdered,
            totalCost: 0,
            unit: ingredient.unit,
            moq: ingredient.moq,
            supplier_id: ingredient.supplier.id,
            part_number: ingredient.part_number,
            no_price: true,
            cost_per_can: 0
          };
        }

        const ingredientCost = totalOrdered * pricePerUnit;
        
        // Get freight cost for this supplier
        const freightCost = 0; // Freight is calculated in OrderSummary
        
        // Calculate total cost (freight is handled in OrderSummary)
        const totalCost = ingredientCost;
        const costPerCan = batchSize.cans_per_batch > 0 ? totalCost / batchSize.cans_per_batch : 0;

        return {
          name: ingredient.name,
          supplier: ingredient.supplier,
          batch_requirement: ingredient.batch_requirement,
          current_level: ingredient.current_level || 0,
          orderQuantity,
          pailsNeeded,
          totalOrdered,
          totalCost,
          unit: ingredient.unit,
          moq: ingredient.moq,
          supplier_id: ingredient.supplier.id,
          part_number: ingredient.part_number,
          has_surplus: false,
          no_price: false,
          cost_per_can: costPerCan
        };
      });

      setOrderItems(calculatedItems);
    } catch (error) {
      console.error('Error calculating order:', error);
      toast.error('Failed to calculate order. Please try again.');
    } finally {
      setCalculatingOrder(false);
    }
  };

  // Helper function to calculate total ingredient cost by supplier
  const totalIngredientCostBySupplier = (supplierId: string): number => {
    return orderItems
      .filter(ing => ing.supplier_id === supplierId)
      .reduce((total, ing) => {
        if (ing.has_surplus || ing.no_price) return total;

        const orderQuantity = ing.orderQuantity;
        const pailsNeeded = Math.ceil(orderQuantity / ing.moq);
        const totalOrdered = pailsNeeded * ing.moq;
        const pricePerUnit = ing.current_price || 0;
        return total + (totalOrdered * pricePerUnit);
      }, 0);
  };

  if (!session) {
    return (
      <>
        <Toaster position="top-right" />
        <Auth onAuthSuccess={() => {}} />
      </>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <Toaster position="top-right" />
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div className="flex items-center space-x-3">
            <GlassWater className="h-8 w-8 text-indigo-600" />
            <h1 className="text-2xl font-bold text-gray-900">
              Drink Ingredient Ordering
            </h1>
          </div>
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setActiveTab('settings')}
              className={`inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md ${
                activeTab === 'settings'
                  ? 'text-white bg-indigo-600'
                  : 'text-gray-700 bg-gray-100 hover:bg-gray-200'
              }`}
            >
              <SettingsIcon className="h-4 w-4 mr-2" />
              Settings
            </button>
            <button
              onClick={() => setActiveTab('ingredients')}
              className={`inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md ${
                activeTab === 'ingredients'
                  ? 'text-white bg-indigo-600'
                  : 'text-gray-700 bg-gray-100 hover:bg-gray-200'
              }`}
            >
              <Package className="h-4 w-4 mr-2" />
              Ingredients
            </button>
            <button
              onClick={() => setActiveTab('flavors')}
              className={`inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md ${
                activeTab === 'flavors'
                  ? 'text-white bg-indigo-600'
                  : 'text-gray-700 bg-gray-100 hover:bg-gray-200'
              }`}
            >
              <GlassWater className="h-4 w-4 mr-2" />
              Flavors
            </button>
            <button
              onClick={handleSignOut}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-gray-700 bg-gray-100 hover:bg-gray-200"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Sign Out
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="space-y-8">
          {activeTab === 'settings' ? (
            <BatchSettings onSettingsUpdate={loadCostSettings} />
          ) : activeTab === 'ingredients' ? (
            <IngredientManagement />
          ) : (
            <>
              <FlavorSelection
                selectedFlavorId={selectedFlavorId}
                onFlavorSelect={setSelectedFlavorId}
              />

              <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg p-6">
                <div className="flex items-center gap-4">
                  <label className="block text-sm font-medium text-gray-700">
                    Current Batch Size (Gallons)
                  </label>
                  <input
                    type="number"
                    value={currentBatchSize}
                    onChange={(e) => setCurrentBatchSize(parseFloat(e.target.value) || 0)}
                    className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  />
                </div>
              </div>

              {selectedFlavorId && (
                <InventoryForm
                  key={selectedFlavorId} // Add key to force re-render on flavor change
                  flavorId={selectedFlavorId}
                  batchSize={currentBatchSize}
                  calculating={calculatingOrder}
                  onCalculate={calculateOrder}
                />
              )}

              {orderItems.length > 0 && batchCosts && batchSize && (
                <OrderSummary
                  items={orderItems}
                  batchCosts={batchCosts}
                  batchSize={batchSize}
                  freightCosts={freightCosts}
                />
              )}
            </>
          )}
        </div>
      </main>
    </div>
  );
}

export default App;