import React from 'react';
import { supabase } from '../lib/supabase';
import { GlassWater } from 'lucide-react';

interface Flavor {
  id: string;
  name: string;
}

interface FlavorSelectionProps {
  selectedFlavorId: string | null;
  onFlavorSelect: (flavorId: string) => void;
}

export function FlavorSelection({
  selectedFlavorId,
  onFlavorSelect,
}: FlavorSelectionProps) {
  const [flavors, setFlavors] = React.useState<Flavor[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    async function loadFlavors() {
      try {
        const { data, error } = await supabase
          .from('flavors')
          .select('*')
          .order('name');

        if (error) throw error;
        setFlavors(data || []);
      } catch (error) {
        console.error('Error loading flavors:', error);
      } finally {
        setLoading(false);
      }
    }

    loadFlavors();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <GlassWater className="animate-spin h-8 w-8" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h2 className="text-lg font-semibold text-gray-900">Select a Flavor</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {flavors.map((flavor) => (
          <button
            key={flavor.id}
            onClick={() => onFlavorSelect(flavor.id)}
            className={`
              p-4 rounded-lg text-left transition-colors
              ${
                selectedFlavorId === flavor.id
                  ? 'bg-indigo-100 border-2 border-indigo-500'
                  : 'bg-white border-2 border-gray-200 hover:border-indigo-300'
              }
            `}
          >
            <span className="font-medium text-gray-900">{flavor.name}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
